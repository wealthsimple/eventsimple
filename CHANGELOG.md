# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.7 - 2022-09-20
### Updated
- TBD

## 0.0.6 - 2022-09-16
### Added
- Separate modules for entity and event models.
  - Previous usage: `include Eventable`
  - New usage: `extend Eventable::Entity` or `extend Eventable::Event`

## 0.0.5 - 2022-09-16
### Added
- Cleaner event output in console

## 0.0.4 - 2022-09-15
### Added
- Raise on state machine check failure instead of setting an activemodel error

## 0.0.3 - 2022-09-15
### Added
- Fix Cops and setup dummy app

## 0.0.2 - 2022-09-15
### Added
- Copy eventable base classes from cash-service

## 0.0.1 - 2022-09-15
### Added
- Initial gem setup
