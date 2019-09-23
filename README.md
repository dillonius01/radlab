# Radlab

## Pre-requisites
Requires Elixir 1.9 and erlang 22 for the CLI firmware uploader tool.
Requires Node to run the sample REST endpoint found in `app.js`

## Running Tests
There are a few unit tests that run via ExUnit. You may run them via `mix test`

## Running the Program
To compile the CLI tool:

```
mix escript.build
```

Now you are ready to run the CLI tool!
To run a sample upload:
```
./radlab --upload
```

To specify a path for the firmware file:
```
./radlab --upload --path other_firmware_file.ex
```

To verify the checksum:
```
./radlab --checksum
```

Note that these options may be combined. For example, to upload and verify:
```
./radlab --upload --checksum
```

## Observed Issues
Sometimes after sending many requests, I have noticed that the native erlang `:httpc` module used for making HTTP requests will sometimes return a tuple of `{:error, :socket_closed_remotely}`. I am not sure if there is a common re-try logic that other HTTP clients use to avoid this issue, or if perhaps I have not propely configured my application to make multiple consecutive requests. I've adjusted the code to error out gracefully when this situation arises, but I do believe it warrants further investigation.

## Questions (Part 1.3)
#### Updating 100+ devices
I would consider spawning a new Elixir process for each update and starting them in parallel. That way, multiple devices could concurrently update.

#### What responses arrive asynchronously via websocket?
If uploading a chunk always returned a 200 and the actual success/failure message came back asynchronously, I would redesign the system such that there would be a process (perhaps an OTP GenServer) responsible for managing a particular device's update. I would have that GenServer subscribe to events on the websocket, so that if a success event was published, it would initiate the next chunk. If a failure event was published, the GenServer would re-try the failed chunk

#### What if responses take 30s?
If the device takes 30s to respond to an HTTP request, I would assume that the TCP connection might close before the response was sent. That suggests that the above websocket design might help alleviate the issue (perhaps every HTTP request times out before a response is sent, but if the success/failure comes back via websocket, then we have a different trigger for trying the next chunk). 

That being said, it might be frustrating to tell when if a device were offline entirely. I might consider adding a "ping" endpoint to confirm if the device were online (this assumes that the "pong" response would take less than 30s). Another option might be to use the checksum endpoint to confirm if the last chunk was received (this also assumes that the checksum enpoint responses are faster).

Or, perhaps we might consider other (non-HTTP) protocols more optimized for high latency environments (I admittedly do not have much expertise in this area!)

#### How to accommodate other protocols?
I tried to structure the code such that the business logic of re-trying is agnostic of the specifics of the protocol used to communicate with devices. There is a `Radlab.Firmware.Client` behaviour module that defines the functions required to perform various firmware-related actions. If switching to MQTT or another protocol, then a developer could implement this behaviour in a new module, and use the existing re-try and runner logic that currently exists.
