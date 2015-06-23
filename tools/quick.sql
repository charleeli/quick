-- --------------------------------------------------------
-- 主机:                           127.0.0.1
-- 服务器版本:                      5.0.18-nt - MySQL Community Edition (GPL)
-- 服务器操作系统:                  Win32
-- HeidiSQL 版本:                  8.3.0.4694
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- 导出 quick 的数据库结构
DROP DATABASE IF EXISTS `quick`;
CREATE DATABASE IF NOT EXISTS `quick` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `quick`;

-- 导出  表 quick.d_account 结构
CREATE TABLE IF NOT EXISTS `d_account` (
  `id` int(11) unsigned NOT NULL COMMENT '系统编号，对应d_user表的uid',
  `pid` varchar(50) NOT NULL COMMENT '平台下发的id',
  `sdkid` int(11) unsigned NOT NULL COMMENT 'sdkid',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `pid_sdkid` (`pid`,`sdkid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='帐号表';

-- 正在导出表  quick.d_account 的数据：~3 rows (大约)
DELETE FROM `d_account`;
/*!40000 ALTER TABLE `d_account` DISABLE KEYS */;
INSERT INTO `d_account` (`id`, `pid`, `sdkid`) VALUES
	(3, '1001', 1),
	(1, '1008', 1),
	(2, '1088', 1);
/*!40000 ALTER TABLE `d_account` ENABLE KEYS */;

-- 导出  表 quick.d_ranking 结构
CREATE TABLE IF NOT EXISTS `d_ranking` (
  `uid` int(10) unsigned NOT NULL COMMENT '玩家ID',
  `attack_win` int(10) unsigned NOT NULL default '0' COMMENT '攻击胜利次数',
  `defend_win` int(10) unsigned NOT NULL default '0' COMMENT '防守胜利次数',
  PRIMARY KEY  (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='排行榜';

-- 正在导出表  quick.d_ranking 的数据：~3 rows (大约)
DELETE FROM `d_ranking`;
/*!40000 ALTER TABLE `d_ranking` DISABLE KEYS */;
INSERT INTO `d_ranking` (`uid`, `attack_win`, `defend_win`) VALUES
	(1, 6, 9),
	(2, 5, 8),
	(3, 10, 12);
/*!40000 ALTER TABLE `d_ranking` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
