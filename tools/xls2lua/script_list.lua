return { 
    --需要require的模块[mod_list的重命名，对应tmp目录下相应模块]
    --res下的最终名字（若script目录有对应转换脚本，将是转换脚本的名字）
    --是否需要转换脚本
    { {'errcode'},              'errcode',              true},
    { {'sys_const'},            'sys_const',            true},
    { {'goods_virtual'},        'goods_virtual'             },
    { {'sign_award_base'},      'sign_award_base',          },
    { {'sign_award_rate'},      'sign_award_rate'           },
    { {'resign_count'},         'resign_count'              },
    { {'resign_cost'},          'resign_cost'               },
    { {'full_duty_award'},      'full_duty_award',      true},
}
