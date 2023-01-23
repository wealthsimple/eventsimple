# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.6.1 - 2023-01-20
  Fix bug where eventable UI would not be able to find the correct entity

## 0.6.0 - 2023-01-16
  Add "Eventable: The UI"

## 0.5.8 - 2023-01-5
  Setup eventable web view

## 0.5.7 - 2023-01-03
### Updated
- Fixed local development setup script
- Fixed bug where timestamps may not be updated on reprojection

## 0.5.6 - 2022-11-28
### Updated
- Only implement retry logic for new records

## 0.5.5 - 2022-11-28
### Updated
- Fixes to consumer migration template
- End consumer correctly on SIGTERM

## 0.5.4 - 2022-11-28
### Updated
- Updated install_generator.rb and templates/create_events.erb to use underscore, instead of downcase.
- Updated isntall_generator/template/event.erb to extend Eventable::Event

## 0.5.3 - 2022-11-18
### Updated
- Add rescue_invalid_transition as optional method to call on an event to customize action taken when can_apply? method returns false

## 0.4.3 - 2022-10-27
### Updated
- Improved error message on event write failures

## 0.4.2 - 2022-10-13
### Updated
- #reproject projects correct entity timestamp values

## 0.4.1 - 2022-10-13
### Updated
- Add auto-applying timestamps to entities
- Disable rails auto updating of created_at and updated_at columns
- apply functions no longer require the entity to be returned

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
- Setup eventable base classes

## 0.0.1 - 2022-09-15
### Added
- Initial gem setup
