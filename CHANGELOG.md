# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.0 - 2022-09-26
### Updated
- Add Rails generators to simplify setup

## 0.2.0 - 2022-09-21
### Updated
- Add Eventable::Outbox::Consumer to implement an outbox

## 0.1.2 - 2022-09-25
### Updated
- Set up working test suite

## 0.1.1 - 2022-09-21
### Updated
- Use `event_klass.const_defined?(:Message)`

## 0.1.0 - 2022-09-21
### Updated
- Return an instance of `event_klass::Message` from `Eventable::DataType#cast_value`
and `Eventable::DataType#deserialize` whenever the type is defined instead of checking
whether input is empty. Otherwise return the hash

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
