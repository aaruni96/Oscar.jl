# this file is executed when the package is first installed to the system
# what exactly does "first install" mean?

using Pkg
Pkg.Registry.add(RegistrySpec(url = "git@github.com:aaruni96/deps-of-oscar.git"))
