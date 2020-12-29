<!--Heya! Thanks for the PR. Please fill out this short little form below to help us review this faster-->

## Description
<!-- Any general story time goes here :) Feel free to add screenshots/recording of your change in action here-->

## Fixes issues: 
- Issue #420
- Issue #69
- ...

## Proposed Changes:
- Change 1
- Change 2
- ...

## Categories
<!-- Delete whichever don't apply -->
- Bug fix <!-- non-breaking change which fixes an issue -->
- New feature <!-- non-breaking change which adds functionality -->
- Breaking change <!-- fix or feature that would cause existing functionality to not work as expected -->
- This change requires a documentation update
- Some existing `functions` got changed <!-- e.g. `utils`, `os`, `apt`, `ask`, etc. -->
- Changes structure of project <!-- major rewrites, large directory changes, etc. -->
- Impacts the flow of how we contribute <!-- IDE changes, `.github` dir, etc. -->

## Architectures
<!--
Please use these emojis here to fill the table below. It will nicely auto-format with spacing, don't worry
Leave empty wherever you do not know / have not tested
✅ = Runs succesfully
⚠️ = Does not work but is handled
❌ = Broken / not working
-->
|   			| `amd64` 	| `armhf` 	| `arm64` 	| Unsepcified 	|
|--------		|-------- 	|-------- 	|-------- 	|----------		|
| Focal 		|			|			|			|				|
| Bionic		|			|			|			|				|
| Buster		|			|			|			|				|
| Stretch		|			|			|			|				|
| Raspbian  	|	N/A		|			|	N/A		|	N/A			|

### Notes
<!-- Optional, in case you'd like to elaborate on some case in the table above -->

## Checklist
<!-- Please note that we also require you to check the CONTRIBUTORS.md file, this is just a short list-->
- [ ] Docs have been made OR are not necessary
    - PR link: 
- [ ] Changes to panel have been made OR are not necessary
    - PR link: 
- [ ] Code is formatted [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#editor-plugins-and-tooling)
- [ ] Shellcheck isn't screaming [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#editor-plugins-and-tooling)
- [ ] Prints to terminal are handled [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#printing-into-the-terminal)
- [ ] I have commented my code, particularly in hard-to-understand areas

## Test scenarios
<!-- Please let us know what has been done or anything else that works/doesn't. Feel free to copy-paste these into the sections below.

- Fresh app install without nginx
    - With only one user
    - With multiple users present
- Fresh Install with nginx present nginx
    - With only one user
    - With multiple users present
- Fresh install and nginx install afterwards
    - With only one user
    - With multiple users present
- Update from version in master
- Upgrade from version in master
- Password gets changed from `box` in app
- User removal from `box` acting on app
- New user in `box` gets added to app
- Sysinfo compatibility
    - Info washed
    - Content available
-->
### Passed

### TODO

### Currently failing



