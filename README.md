# Gems #

Contains all the ruby gems specific to Octomatic.

# Building

## Build all gems

Provided is a `build.sh` script. Execute it. It will build all the gems

## Individual Build

If you want to build a specific gem peform these steps

- `cd` to the gem's dir
- `gem build gemname.gemspec` For the gemspec file that is present. This will create a .gem file
- Execute `gem install gemname-0.x.y.gem`. This will install the gem alongwith it's rdoc.


## Note:

- If permissions required then type 'sudo' for ubuntu and give super user permissions to install gem
- If any gem fail because of dependencies, try install dependencies manually.


# ReadME

Each gem provides their own README. Refer to the gem for this section.
