# coding=utf-8
from __future__ import division
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
from future import standard_library
from future.builtins import *

import sys
from inspect import currentframe
from locale import getpreferredencoding
from os import (listdir, mkdir)
from os.path import (isfile, join, splitext, exists, basename)
from collections import defaultdict

from xlrd import open_workbook, XLRDError
import unicodecsv as csv

if not sys.stdout.encoding:
    reload(sys)
    sys.setdefaultencoding("utf-8")

if sys.stderr.encoding == 'cp936':
    class UnicodeStreamFilter(object):
        def __init__(self, target):
            self.target = target
            self.encoding = 'utf-8'
            self.errors = 'replace'
            self.encode_to = self.target.encoding

        def write(self, s):
            if isinstance(s, bytes):
                s = s.decode('utf-8')
            s = s.encode(self.encode_to, self.errors).decode(self.encode_to)
            self.target.write(s)
    sys.stderr = UnicodeStreamFilter(sys.stderr)

begin_temple = """
return {
"""
row_temple = """
    [%s] = {
"""
cell_temple = """\
        %s = %s,
"""
row_end_temple = """\
    },
"""
end_temple = """
}
"""

def assertx(value, message):
    if __debug__ and not value:
        try:
            code = compile('1 / 0', '', 'eval')
            exec(code)
        except ZeroDivisionError:
            tb = sys.exc_info()[2].tb_next
            assert tb
            raise AssertionError, str(message).encode('utf-8'), tb
    return value

def csv_from_excel(xls_name):
    workbook = open_workbook(xls_name)
    for sheet in workbook.sheets():
        with open(sheet.name + '.csv', 'wb') as csv_file:
            writer = csv.writer(csv_file, quoting=csv.QUOTE_NONNUMERIC)
            for rownum in range(sheet.nrows):
                writer.writerow(sheet.row_values(rownum))

#基础类型
type_tbl = {
    'int': int,
    'float': float,
    'string': str,
    'formula': str,
}


default_tbl = {
    'int': 0,
    'float': 0.0,
    'string': '',
    'formula': '',
}

legal_extra_types = ('default', 'key', 'ignored')

row_keys_ = {}
row_values_ = {}

def cell_to_value(col_type, value):
    if col_type.startswith('struct'):
        templates = col_type.split("(")[1].split(")")[0]
        template_lst = templates.split(",")
        values = value.strip()
        value_lst = values.split(",")

        value = {}
        for i, j in enumerate(template_lst):
            if i >= len(value_lst):
                break
            if j.find("[") != -1 and j.find("]") != -1:
                key = j.split("[")[1].split("]")[0]
                sub_col_type = j.split("[")[0]
            else:
                key = i + 1
                sub_col_type = j
            value[key] = cell_to_value(sub_col_type, value_lst[i])

    elif col_type in type_tbl:
        if col_type == 'int':
            try:
                value = int(value)
            except:
                value = int(eval(value))
        elif col_type == 'float':
            try:
                value = float(value)
            except:
                value = eval(value)
        elif col_type == 'string':
            try:
                value = int(value)
            except:
                pass

            value = str(value)
        else:
            value = type_tbl[col_type](value)

    else:
        try:
            value = int(value)
            value = unicode(value)
        except:
            pass
        enum_name_tbl = enum_tbl[col_type]
        assertx(value in enum_name_tbl,
                '未定义枚举值[%s]' % (value))
        value = enum_name_tbl[value]
    return value


def sheet_to_dict(sheet):
    type_row = sheet.row_values(0)
    name_row = sheet.row_values(1)
    col_types = []
    row_key = None
    ignored_names = []
    for i, column in enumerate(type_row):
        try:
            if not column:
                print('     --%d列类型为空, 忽略之后列' % (i + 1))
                type_row = type_row[:i]
                break
            col_type = column
            if column.find('@') != -1:
                col_type, extra_type = column.split('@')
                assertx(extra_type in legal_extra_types,
                        '@后描述符不正确[%s], 只能为%s' % (extra_type, ' '.join(legal_extra_types)))
                if extra_type == 'ignored':
                    ignored_names.append(name_row[i])
                elif extra_type == 'key':
                    row_key = name_row[i]
                    row_keys_[sheet.name] = row_key
            #assertx(name_row[i], '命名不能为空: 列%s' % i)
            if col_type.startswith('list'):
                val_type = col_type.split('<')[1].split('>')[0]
                if val_type not in type_tbl and not val_type.startswith('struct'):
                    assertx(val_type in enum_tbl, '未定义枚举类型[%s]' % val_type)
                col_type = 'list'

            elif col_type.startswith('dict'):
                val_type = col_type.split('<')[1].split('>')[0]
                if val_type not in type_tbl and not val_type.startswith('struct'):
                    assertx(val_type in enum_tbl, '未定义枚举类型[%s]' % val_type)
                col_type = 'dict'

            elif col_type not in type_tbl and not col_type.startswith('struct'):
                assertx(col_type in enum_tbl, '未定义枚举类型[%s]' % col_type)

            col_types.append(col_type)
        except:
            print('----行3 列%s[%s] 错误' % (i + 1, column))
            raise

    normal_name_tbl = {}
    list_name_tbl = defaultdict(list)
    for i, name in enumerate(name_row):
        if name.find('|') != -1:
            #print(name)
            list_name_tbl[name].append(i)
        else:
            normal_name_tbl[name] = i

    title_row = sheet.row_values(2)
    keys_ = {}
    empty_row = set([''])
    for rownum in range(3, sheet.nrows):
        try:
            row = sheet.row_values(rownum)
            if set(row) == empty_row:
                break
            null_index_tbl = {}
            for i, column in enumerate(type_row):
                null_index_tbl[i] = (row[i] == '')

                col_type = col_types[i]

                if col_type == 'list':
                    if row[i] == '':
                        row[i] = []
                    else:
                        row[i] = str(row[i])
                        val_type = column.split('<')[1].split('>')[0]
                        values = [val.strip() for val in row[i].split(',')]
                        row[i] = [cell_to_value(val_type, val) for val in values]

                elif col_type == 'dict':
                    if row[i] == '':
                        row[i] = {}
                    else:
                        row[i] = str(row[i])
                        val_type = column.split('<')[1].split('>')[0]
                        values = [val.strip() for val in row[i].split(',')]
                        lsts = [cell_to_value(val_type, val) for val in values]
                        row[i] = {val['id']:val for val in lsts}

                elif row[i] == '' and (column.endswith('@default') or column.endswith('@ignored')):
                    if col_type in type_tbl:
                        row[i] = default_tbl[col_type]
                    elif col_type.startswith('struct'):
                        row[i] = {}
                    else:
                        row[i] = 0

                else:
                    assertx(row[i] != '', '行%s 列[%s] 不能为空' % (rownum + 1, title_row[i]))
                    row[i] = cell_to_value(col_type, row[i])
                    if name_row[i] == row_key:
                        assertx(row[i] not in keys_,
                                'key列 %s 值重复 %s' % (title_row[i], row[i]))
                        keys_[row[i]] = True
            data = {}
            for name, index in normal_name_tbl.iteritems():
                if name == '':
                    continue
                if name in ignored_names:
                    continue
                data[name] = row[index]
            list_name_len_tbl = {}
            for name, indexes in list_name_tbl.iteritems():
                choosed_indexs = []
                first = False
                for i in reversed(indexes):
                    if not first and null_index_tbl[i]:
                        continue
                    if not first:
                        first = True
                    choosed_indexs.append(i)
                old_name = name
                name_num, name = name.split('|')
                data[name] = [
                    row[i] for i in reversed(choosed_indexs)]
                if name_num:
                    data_len = list_name_len_tbl.get(name_num)
                    if data_len:
                        assertx(len(data[name]) == data_len,
                        '合并列[%s]的长度[%s]与同组[%s]合并列长度[%s]不一致' %
                                (old_name, len(data[name]), name_num, data_len))
                    else:
                        list_name_len_tbl[name_num] = len(data[name])
        except:
            print('----行%s 列%s[%s] 错误' % (rownum + 1, i, title_row[i]))
            raise
        yield data


def format_value(value):
    if isinstance(value, basestring):
        if '\n' in value:
            form = '[=[%s]=]'
        elif '"' in value:
            form = '[[%s]]' if "'" in value else "'%s'"
        else:
            form = '"%s"'

        return form % value
    elif isinstance(value, list):
        value = ', '.join([format_value(v) for v in value])
        value = '{%s}' % value

    elif isinstance(value, dict):
        value = ', '.join(["[%s] = %s"%(format_value(k), format_value(v)) for k, v in value.items()])
        value = '{%s}' % value

    return str(value)

def to_lua(name, data, xls_name, output):
    if not exists(output):
        mkdir(output)
    with open(join(output, name + '.lua'), 'wb') as file:
        comment = '-- %s' % xls_name
        file.write(comment.encode('utf-8'))
        file.write(begin_temple)
        for i, row in enumerate(data):

            key_name = row_keys_.get(name, 'id')
            key = row.get(key_name, i + 1)

            if isinstance(key, basestring):
                key = format_value(key)
            file.write(row_temple % key)
            for key, value in row.items():
                if isinstance(value, basestring):
                    value = format_value(value)
                elif isinstance(value, list):
                    value = ', '.join([format_value(v) for v in value])
                    value = '{%s}' % value
                elif isinstance(value, dict):
                    value = ', '.join(["[%s] = %s"%(format_value(k), format_value(v)) for k, v in value.items()])
                    value = '{%s}' % value

                cell = cell_temple % (key, value)
                file.write(cell.encode('utf-8'))
            file.write(row_end_temple)
        file.write(end_temple)

def excel_sheets(*args, **kw):
    with open_workbook(*args, on_demand=True, ragged_rows=True, **kw) as (
    book):
        for i in range(book.nsheets):
            try:
                yield book.sheet_by_index(i)
            finally:
                book.unload_sheet(i)


def sheet_row_values(sheet, rowx):
    return (sheet.cell_value(rowx, colx)
            for colx in range(sheet.row_len(rowx)))


def convet(xls_name, output, file_names_):
    workbook = open_workbook(xls_name)#, encoding_override='gbk')
    for sheet in workbook.sheets():
        if sheet.nrows == 0:
            continue
        if sheet.name.startswith('_'):
            print('  --忽略[%s]转换' % (sheet.name))
            continue
        try:
            print('    ', sheet.name)
            assertx(sheet.name not in file_names_,
                    '%s %s 文件名 %s 重复' % (file_names_.get(sheet.name), xls_name, sheet.name))
            data = sheet_to_dict(sheet)

            to_lua(sheet.name, data, xls_name, output)
            file_names_[sheet.name] = xls_name
        except Exception as e:
            print('转换失败', xls_name, sheet.name)
            raise


enum_tbl = {}

def convet_enumerate(xls_name, path):
    assertx(isfile(xls_name), '必须有枚举表enumerate.xls')
    with open_workbook(xls_name, on_demand=True) as workbook:
        assertx(workbook.nsheets == 1, '枚举表只能有一个sheet')
        sheet = workbook.sheet_by_index(0)
    for row in sheet_to_dict(sheet):
        enum_name = row['enum_name']
        with open_workbook(path + row['file_name'], on_demand=True) as workbook:
            try:
                sheet = workbook.sheet_by_name(row['sheet_name'])
            except XLRDError as e:
                print('枚举表转换失败')
                print('%s 没有Sheet %s' % (row['file_name'], row['sheet_name']))
                raise

        try:
            name_row = sheet.row_values(1)
            id_index = name_row.index('id')
            name_index = name_row.index('name')
            name_to_id = {}
            idx_ = {}
            pre_name_to_id = enum_tbl.get(enum_name)
            if pre_name_to_id:
                pre_idx_ = set(pre_name_to_id.itervalues())
            for rowx in range(3, sheet.nrows):
                idx = sheet.cell_value(rowx, id_index)
                if idx == '':
                   break
                name = sheet.cell_value(rowx, name_index)
                assertx(name not in name_to_id, '枚举名重复[%s]' % name)
                assertx(idx not in idx_, '枚举名ID重复[%s]' % idx)
                if pre_name_to_id:
                    assertx(name not in pre_name_to_id, '与其他同类型表 枚举名重复[%s]' % name)
                    assertx(idx not in pre_idx_, '与其他同类型表 枚举名ID重复[%s]' % idx)

                try:
                    name = int(name)
                    name = unicode(name)
                except:
                    pass

                name_to_id[name] = int(idx)
                idx_[idx] = True
            if pre_name_to_id:
                pre_name_to_id.update(name_to_id)
                name_to_id = pre_name_to_id
            enum_tbl[enum_name] = name_to_id
        except Exception as e:
            print('枚举表错误', row['file_name'])
            raise

def convet_xls_file(path, output, file_names_):
    root, ext = splitext(path)
    if ext != '.xls':
        return
    head = basename(path)
    if head.startswith('_'):
        return
    convet(path, output, file_names_)


if __name__ == '__main__':
    PATH = './xls/'
    OUTPUT = 'tmp/'

    file_names_ = {}
    convet_enumerate(join(PATH, 'enumerate.xls'), PATH)
    for name in listdir(PATH):
        path = join(PATH, name)
        if not isfile(path):
            continue
        output = OUTPUT
        print(name)
        convet_xls_file(path, output, file_names_)

    print('-' * 40)
    for name in listdir(PATH):
        path = join(PATH, name)
        if isfile(path) or name[0] == '.':
            continue
        file_names_ = {}
        print('分区表资源%s' % name)
        for sub_name in listdir(path):
            sub_path = join(path, sub_name)
            if not isfile(sub_path):
                continue
            output = join(OUTPUT, name)
            print(sub_name)
            convet_xls_file(sub_path, output, file_names_)
        print('-' * 20)
