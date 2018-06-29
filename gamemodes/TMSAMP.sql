-- phpMyAdmin SQL Dump
-- version 4.6.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: May 04, 2016 at 06:58 PM
-- Server version: 5.5.49-0+deb7u1-log
-- PHP Version: 5.5.33-1~dotdeb+7.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `TMSAMP`
--

-- --------------------------------------------------------

--
-- Table structure for table `p_accounts`
--

CREATE TABLE `p_accounts` (
  `Username` varchar(20) CHARACTER SET latin1 NOT NULL,
  `Account_ID` int(11) NOT NULL,
  `Password` varchar(128) CHARACTER SET latin1 NOT NULL,
  `pIPv4` varchar(17) COLLATE utf8_unicode_ci NOT NULL,
  `pRegistered_Date` varchar(20) CHARACTER SET latin1 NOT NULL,
  `pTime_Played` int(10) UNSIGNED NOT NULL DEFAULT '0',
  `pLastVisit` int(11) NOT NULL,
  `pAdminLevel` int(11) NOT NULL,
  `pMoney` int(11) NOT NULL,
  `pKills` int(11) NOT NULL,
  `pDeaths` int(11) NOT NULL,
  `pKillAssists` int(11) NOT NULL,
  `pKillStreaks` int(11) NOT NULL,
  `pExprience` int(11) NOT NULL,
  `pLast_Exp_Gained` int(11) NOT NULL,
  `pLevel` int(11) NOT NULL DEFAULT '1',
  `pTier_Points` int(11) NOT NULL,
  `pTravelled_Distance` int(11) NOT NULL,
  `pFavourite_Vehicle` int(11) NOT NULL DEFAULT '0',
  `pFavourite_Map` int(11) NOT NULL DEFAULT '-1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `p_customization`
--

CREATE TABLE `p_customization` (
  `Account_ID` int(11) NOT NULL,
  `Username` varchar(24) CHARACTER SET latin1 NOT NULL,
  `vmodel` int(11) NOT NULL,
  `ID` int(11) NOT NULL,
  `objectmodel` int(11) NOT NULL,
  `offsetx` float NOT NULL,
  `offsety` float NOT NULL,
  `offsetz` float NOT NULL,
  `offsetrx` float NOT NULL,
  `offsetry` float NOT NULL,
  `offsetrz` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `s_maps`
--

CREATE TABLE `s_maps` (
  `Map_Name` varchar(32) CHARACTER SET latin1 NOT NULL,
  `Map_Type` int(11) NOT NULL,
  `Mapid` int(11) NOT NULL,
  `Lowest_Z` float NOT NULL DEFAULT '0',
  `CheckLowestZ` int(11) NOT NULL DEFAULT '1',
  `Weatherid` int(11) NOT NULL DEFAULT '666',
  `Interpolation_Index` int(11) NOT NULL DEFAULT '0',
  `Max_Grids` int(11) NOT NULL DEFAULT '3'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `s_map_objects`
--

CREATE TABLE `s_map_objects` (
  `MapName` varchar(32) CHARACTER SET latin1 NOT NULL,
  `Mapid` int(11) NOT NULL,
  `Modelid` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `rX` float NOT NULL,
  `rY` float NOT NULL,
  `rZ` float NOT NULL,
  `Draw_Distance` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `s_map_pickups`
--

CREATE TABLE `s_map_pickups` (
  `MapName` varchar(32) CHARACTER SET latin1 NOT NULL,
  `Mapid` int(11) NOT NULL,
  `Pickup_Type` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `s_map_pickups`
--

INSERT INTO `s_map_pickups` (`MapName`, `Mapid`, `Pickup_Type`, `x`, `y`, `z`) VALUES
('Hanger 18', 3, 9, -1300.04, -447.608, 13.773),
('Diablo Pass', 5, 1, 666.881, 666.47, 7.6891),
('Suburbs', 4, 9, -2283.56, 2658.31, 59.5296),
('Suburbs', 4, 4, -2275.45, 2627.59, 73.1405),
('Suburbs', 4, 3, -2276.21, 2688, 73.1405),
('Suburbs', 4, 0, -2276.32, 2657.63, 73.1406),
('Suburbs', 4, 4, -2368.37, 2706.6, 76.4174),
('Suburbs', 4, 6, -2436.28, 2696.42, 75.8605),
('Suburbs', 4, 1, -2586.82, 2686.15, 81.8907),
('Suburbs', 4, 8, -2731.47, 2685.7, 106.361),
('Suburbs', 4, 2, -2782.76, 2581.54, 104.963),
('Suburbs', 4, 1, -2783.43, 2325.25, 77.5866),
('Suburbs', 4, 10, -2834.28, 2364.64, 105.834),
('Suburbs', 4, 5, -2625.51, 2531.51, 27.4684),
('Suburbs', 4, 10, -2547.42, 2540.06, 20.2646),
('Suburbs', 4, 6, -2493.9, 2483.38, 17.8144),
('Suburbs', 4, 9, -2455.18, 2355.17, 4.9834),
('Suburbs', 4, 1, -2372.58, 2333.49, 4.6068),
('Suburbs', 4, 5, -2336.32, 2293.6, 4.614),
('Suburbs', 4, 8, -2238.38, 2364.79, 9.8124),
('Downtown', 2, 1, -2028.53, -1012.73, 31.9775),
('Downtown', 2, 3, -2021.83, -730.802, 31.9733),
('Freeway', 6, 7, 1609.41, 25.0181, 28.175),
('Freeway', 6, 5, 1614.33, 14.616, 22.7961),
('Freeway', 6, 0, 1620.57, 21.7116, 24.2455),
('Freeway', 6, 8, 1623.38, 15.1614, 21.6679),
('Freeway', 6, 5, 1552.85, 257.735, 15.8049),
('Freeway', 6, 2, 1557.4, 230.237, 24.5992),
('Freeway', 6, 10, 1602.35, 233.14, 27.8375),
('Freeway', 6, 1, 1572.46, 277.87, 17.2608),
('Freeway', 6, 3, 1686.57, 236.914, 13.6261),
('Freeway', 6, 8, 1629.69, 238.543, 30.4624),
('Freeway', 6, 4, 1660.47, 337.215, 30.4808),
('Freeway', 6, 2, 1688.35, 406.58, 30.7139),
('Freeway', 6, 9, 1706.54, 403.517, 30.7386),
('Freeway', 6, 5, 1623.97, 15.9242, 36.9514),
('Freeway', 6, 1, 1653.35, 275.812, 30.3366),
('Freeway', 6, 0, 1608.93, 90.1883, 37.8216),
('Freeway', 6, 3, 1629.64, 116.932, 31.5592),
('Freeway', 6, 4, 1606.63, 155.343, 34.3856),
('Freeway', 6, 6, 1601.89, 131.31, 29.9041),
('Freeway', 6, 3, 1768.63, 95.4393, 34.0004),
('Freeway', 6, 6, 1810.27, 169.544, 32.4096),
('Freeway', 6, 9, 1710.95, 352.784, 19.2724),
('Freeway', 6, 4, 1826.56, 331.363, 19.4096),
('Freeway', 6, 3, 1943.88, 331.108, 27.5208);

-- --------------------------------------------------------

--
-- Table structure for table `s_map_spawns`
--

CREATE TABLE `s_map_spawns` (
  `MapName` varchar(32) NOT NULL,
  `Mapid` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `Angle` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `s_map_spawns`
--

INSERT INTO `s_map_spawns` (`MapName`, `Mapid`, `x`, `y`, `z`, `Angle`) VALUES
('Freeway', 6, 1603.9, 71.4151, 37.9903, 6.8525),
('Freeway', 6, 1829.62, 189.509, 30.2292, 66.6),
('Freeway', 6, 1628.97, 24.9407, 36.3872, 21.87),
('Freeway', 6, 1612.74, 24.4742, 36.544, 20.21),
('Freeway', 6, 1630.49, 241.534, 29.8191, 307.76),
('Freeway', 6, 1599.93, 294.921, 20.2945, 264.33),
('Freeway', 6, 1612.04, 316.557, 20.6563, 239.71),
('Freeway', 6, 1660.3, 340.653, 29.917, 191.67),
('Freeway', 6, 1685.81, 398.595, 29.9948, 162.05),
('Freeway', 6, 1703.38, 393.986, 29.9478, 160.39);

-- --------------------------------------------------------

--
-- Table structure for table `s_temp_race_quit_list`
--

CREATE TABLE `s_temp_race_quit_list` (
  `Username` varchar(24) NOT NULL,
  `checkpointIndex` int(11) NOT NULL DEFAULT '-1'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `p_accounts`
--
ALTER TABLE `p_accounts`
  ADD PRIMARY KEY (`Account_ID`),
  ADD UNIQUE KEY `Username` (`Username`);

--
-- Indexes for table `p_customization`
--
ALTER TABLE `p_customization`
  ADD PRIMARY KEY (`Account_ID`,`Username`,`vmodel`,`ID`);

--
-- Indexes for table `s_maps`
--
ALTER TABLE `s_maps`
  ADD PRIMARY KEY (`Mapid`),
  ADD UNIQUE KEY `Map_Name` (`Map_Name`);

--
-- Indexes for table `s_map_objects`
--
ALTER TABLE `s_map_objects`
  ADD PRIMARY KEY (`MapName`,`Mapid`),
  ADD KEY `Mapid` (`Mapid`);

--
-- Indexes for table `s_map_pickups`
--
ALTER TABLE `s_map_pickups`
  ADD KEY `Mapid` (`Mapid`);

--
-- Indexes for table `s_map_spawns`
--
ALTER TABLE `s_map_spawns`
  ADD KEY `Mapid` (`Mapid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `p_accounts`
--
ALTER TABLE `p_accounts`
  MODIFY `Account_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `s_map_objects`
--
ALTER TABLE `s_map_objects`
  ADD CONSTRAINT `s_map_objects_ibfk_1` FOREIGN KEY (`Mapid`) REFERENCES `s_maps` (`Mapid`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `s_map_objects_ibfk_2` FOREIGN KEY (`Mapid`) REFERENCES `s_maps` (`Mapid`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `s_map_objects_ibfk_3` FOREIGN KEY (`Mapid`) REFERENCES `s_maps` (`Mapid`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `s_map_objects_ibfk_4` FOREIGN KEY (`Mapid`) REFERENCES `s_maps` (`Mapid`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
