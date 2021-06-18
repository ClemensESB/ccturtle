-- MySQL Script generated by MySQL Workbench
-- Thu Jun 17 08:25:28 2021
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, 
UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, 
FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE,
SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
USE `turtle`;




-- -----------------------------------------------------
-- Table `mydb`.`position`
-- -----------------------------------------------------
CREATE TABLE
IF NOT EXISTS `turtle`.`position`
(
  `id` INT NOT NULL AUTO_INCREMENT,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatetAt` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `x` INT NOT NULL,
  `y` INT NOT NULL,
  `z` INT NOT NULL,
  PRIMARY KEY(`id`),
  UNIQUE INDEX `deviceId_UNIQUE`(`position` ASC));


-- -----------------------------------------------------
-- Table `mydb`.`blocks`
-- -----------------------------------------------------
CREATE TABLE
IF NOT EXISTS `turtle`.`blocks`(
  `id` INT NOT NULL AUTO_INCREMENT,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatetAt` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `position_id` INT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `state` VARCHAR(50) NOT NULL,
  `tags` VARCHAR(50) NOT NULL,
  `forge` VARCHAR(50) NOT NULL,
  PRIMARY KEY(`id`),
  INDEX `fk_base_position1_idx`(`position_id` ASC),
  CONSTRAINT `fk_base_position1`
    FOREIGN KEY(`position_id`) REFERENCES `turtle`.`position`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION);


-- -----------------------------------------------------
-- Table `mydb`.`devices`
-- -----------------------------------------------------
CREATE TABLE
IF NOT EXISTS `turtle`.`devices`(
  `id` INT NOT NULL AUTO_INCREMENT,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatetAt` TIMESTAMP NULL DEFAULT NULL ON
UPDATE CURRENT_TIMESTAMP,
  `name` VARCHAR(32) NOT NULL,
  `position_id` INT NOT NULL,
  PRIMARY KEY(`id`),
  INDEX `fk_devices_position_idx`(`position_id` ASC),
  CONSTRAINT `fk_devices_position`
    FOREIGN KEY(`position_id`)
    REFERENCES `turtle`.`position`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION);


SET SQL_MODE
=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS
=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS
=@OLD_UNIQUE_CHECKS;
