# AMPLIFY Portable High Level Interface Specification

The core **AMPLIFY Portable** communication backbone is based on a
network-based publish-subscribe mechanism. This allows every node in the
network to operate independently from one another, without having to have any
knowledge of the other devices present in the network. Every input node can
publish any number of data streams and output nodes can subscribe to the number
of streams required to perform its output function.

This architecture is based around a central node which relays messages and
streams and manages the publish-subscribe channels. This node is present at a
well-known location in the network and input/output devices connect to it upon
joining the network. The central node also provides a method of discovering
client nodes present in the network and more importantly services they provide
in a service registry. Client nodes register channels they want to provide and
the type of data these channels contain before starting to publish data on said
channel. Should the channel become unavailable, e.g. whenever a client leaves
the network, it should be removed from the service registry as well.

The architecture and specifically the central node described in the previous
paragraph is reasonably generic, so that it can be implemented using any number
of technologies. For the first deployment near future of **AMPLIFY Portable**,
the functionality for the central node will be provided by a **Redis** server
and its publish-subscribe features.

Redis is an open source in-memory key-value store with a low memory footprint
and is designed for high throughput and low latency with a simple communication
protocol. It also supports master-replica replication, making it possible to
scale out the central node to multiple processes and/or hosts should the need
for it arise.

To simplify interaction with the central Redis node and provide a coherent
interface across different client implementations, interface libraries will be
provided which clients can use to interact with the system. These libraries
will be specific to the programming language used the implement the client and
will be provided on a on-demand basis.

## Example

This section provides an example of how a client library might interact with
the central node. Also note, that in general, each channel on the central node
will have a single publisher and can have multiple subscribers.

*NB:* These examples pertains to the client interface library
and most of the implementation details will be transparent to the actual client
code.

### Input Node

Input nodes provide streams to the system, e.g. devices such as sensors.

1. Client input node connects to the Redis central node at a well-known
   address.
2. Client registers its details with the central node as a JSON data structure
   under a key of type *hash* meant for this purpose. This data structure
   might contain information such as device type (input, output or both),
   number of streams it provides.
3. The client device gets ready for publishing data, it registers a new service
   with the central node under a key of type *hash* intended for this
   purpose. The description of the service contains the name of the stream and
   the type of data it will contain (numbers, boolean, ...) and whether it will
   be continuous or sporadic. Registering the service before starting to
   publish data also prevents naming conflicts with other services, as in that
   case the central node will simply reject the service registration.
4. The client node can start publishing data to the chosen publish-subscribe
   channel.

### Output Node

Output nodes are devices that consume data by ingesting data from
publish-subscribe channels. They can use this data for instance for rendering
data to a screen.

1. Client output node connects to the Redis central node at a well-known
   address.
2. Client registers its details with the central node as a JSON data structure
   under a key of type **hash** meant for this purpose. This data structure
   might contain information such as device type (input, output or both).
3. The client device gets ready for ingesting data. It queries the service
   registry for streams that are available in the system and learns about the
   type of data it can expect from them.
4. It subscribes to the chosen streams by providing a callback function, which
   will be triggered every time the publisher associated with the channel
   publishes a new sample.

### Notes

It is important to note here that the output device can subscribe to any number
of channels needed to accomplish its function. The same is true for input
devices, though in general, they only publish on a single main channel.

Further, nodes in the system may not be strictly input or output devices, but
a combination of both. For instance, a node might ingest several raw data
streams, process them in some way and republish the processed data on a new
channel.

### Cleanup

Whenever a client node decides to go offline and leave the network or stop
providing a service, it has to unregister its services from the service
registry and remove itself from the client registry before disconnecting.

Should a client become unresponsive or crash, the service and device registries
will become outdated and potentially provide unreliable information. In order
to prevent this from happening, a heartbeat mechanism should be implemented, in
which clients refresh a timestamp at a certain frequency in the device registry
with which other clients can gauge whether a client is still available. This
mechanism potentially requires a cleanup process which removes stale clients
from the registries.

## API

This section defines the API that users of the interface library can program
against. Every concrete implementation of the interface library should support
these methods. Method signatures use a Typescript-like syntax for annotating
types. These signatures are not necessarily authoritative, but act merely as
pseudocode.

### `connect(host: string, type: 'input' | 'output' | 'io', device_info: any?): Connection`

This function acts as the main entry point for the application. It establishes
a connection to the Redis server at the host/port identified by the string
`host`. A device should also register itself as either an `input` device,
`output` device and general `io` if it can perform both functions. Optionally
this method also accepts a dictionary-like object containing device
information. The contents of this object are as of yet unspecified.

The function establishes the connection to the server and returns a `Connection`
object through which all future communication shall be conducted.
