# sample-source
Sample repository holding some basic usable source for a service thingy.

This base already includes
 - express
 - express-body-parser
 - systemd

 It already implements the Startup. The startup prepares and exposes the SCI.

 SCI = Service Communication Interface. Usually refered to as API.
 As Service Communication Interface fits is actually the accurate description I call it SCI here.

# Exposing the SCI
Here we already have some configuration introduced.

- taking systemd socket as input stream when we have `SOCKETMODE` variable in the environment
- listening on TCP port `PORT` if we have it as environment variable
- listening on TCP port `configmodule.defaultPort` when we donot have any environment variables set



