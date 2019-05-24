# Server configuration reproducers

No-frills scripts for rebuilding the servers for some of my research
projects from scratch.  The specific configurations are probably not
of any use to anyone who isn’t working directly with me on those
projects, but if you want to steal the framework for your own sysadmin
chores, feel free.  For clarity, all the code is under the [Apache 2
license](LICENSE).

There is one subdirectory per server type, plus the “common” directory.
To rebuild a server, starting from a scratch install of the base OS
(usually Ubuntu 18.04LTS), clone this repo (or just copy a checkout)
into /root and then run `./prepare-server <server-type>`.

Bad things will probably happen if you run `prepare-server` on a
computer that hasn’t just been initialized.
