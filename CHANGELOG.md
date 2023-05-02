# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.9.1 - 2023-04-29
  - add `metadata_klass` configuration so it can be easily overwritten

## 0.9.0 - 2023-04-25
  - update timestamp of projection on deleted events. We originally had deleted
    events act as a `noop` but when checking `model.project_matches_events?` it would fail
    since the original projection would have included the timestamp update.

    We don't want to require a projection of every instance of a model when deleting an event so
    we now update the timestamps on deleted event projections.
## 0.8.0 - 2023-04-18
  - Rename gem to Eventsimple

## 0.7.3 - 2023-04-14
  - Adding some missing tests

## 0.7.2 - 2023-04-06
  - Remove use of ApplicationRecord.descendants to determine the list of models
    to display in the UI. This conflicts with components using packwerk.
    A side effect of this change is that the UI will no longer display STI models.
    STI models did not work properly in the UI anyway, so this is ok.

## 0.7.1 - 2023-04-11
  Breaking Change:
    - Eventsimple no longer requires a Dispatcher class to be defined.
      Instead, dispatchers must now be registered in the event configuration.
      Each dispatcher must inherit from Eventsimple::Dispatcher

## 0.7.0 - 2023-03-29
  - Remove custom database role configuration as it is not needed
  - Allow concurrency retry count to be configurable
  - Require Rails >= 7.0.0. Eventsimple is not compatible with older versions.

  Breaking Change:
    - aggregate_id is now a required property on event configuration

## 0.6.5 - 2023-02-02
  Fix various UI styling and overflow bugs

## 0.6.4 - 2023-01-20
  Avoid using redirect to prevent issues with internal proxies

## 0.6.3 - 2023-01-20
  Remove turbo use, as it is not essential

## 0.6.2 - 2023-01-20
  Add placeholder class for events deleted in code

## 0.6.1 - 2023-01-20
  Fix bug where eventsimple UI would not be able to find the correct entity

## 0.6.0 - 2023-01-16
  Add "Eventsimple: The UI"

## 0.5.8 - 2023-01-5
  Setup eventsimple web view

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
- Updated isntall_generator/template/event.erb to extend Eventsimple::Event

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
- Add Eventsimple::Outbox::Consumer to implement an outbox

## 0.1.2 - 2022-09-25
### Updated
- Set up working test suite

## 0.1.1 - 2022-09-21
### Updated
- Use `event_klass.const_defined?(:Message)`

## 0.1.0 - 2022-09-21
### Updated
- Return an instance of `event_klass::Message` from `Eventsimple::DataType#cast_value`
and `Eventsimple::DataType#deserialize` whenever the type is defined instead of checking
whether input is empty. Otherwise return the hash

## 0.0.6 - 2022-09-16
### Added
- Separate modules for entity and event models.
  - Previous usage: `include Eventsimple`
  - New usage: `extend Eventsimple::Entity` or `extend Eventsimple::Event`

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
