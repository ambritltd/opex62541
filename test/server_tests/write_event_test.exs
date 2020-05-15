defmodule ServerWriteEventTest do
  use ExUnit.Case

  alias OpcUA.{NodeId, Client}

  defmodule MyServer do
    use OpcUA.Server
    alias OpcUA.{NodeId, Server, QualifiedName}

    # def start_link() do
    #   GenServer.start(__MODULE__, self(), [])
    # end

    # Use the `init` function to configure your server.
    def init(parent_pid) do
      {:ok, s_pid} = Server.start_link()
      :ok = Server.set_default_config(s_pid)

      {:ok, _ns_index} = Server.add_namespace(s_pid, "Room")

      # Object Node
      requested_new_node_id =
        NodeId.new(ns_index: 1, identifier_type: "integer", identifier: 10002)

      parent_node_id = NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 85)
      reference_type_node_id = NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 35)
      browse_name = QualifiedName.new(ns_index: 1, name: "Test1")
      type_definition = NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 58)

      :ok = Server.add_object_node(s_pid,
        requested_new_node_id: requested_new_node_id,
        parent_node_id: parent_node_id,
        reference_type_node_id: reference_type_node_id,
        browse_name: browse_name,
        type_definition: type_definition
      )

      # Variable Node
      requested_new_node_id =
        NodeId.new(ns_index: 1, identifier_type: "integer", identifier: 10001)

      parent_node_id = NodeId.new(ns_index: 1, identifier_type: "integer", identifier: 10002)
      reference_type_node_id = NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 47)
      browse_name = QualifiedName.new(ns_index: 1, name: "Var")
      type_definition = NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 63)

      :ok = Server.add_variable_node(s_pid,
        requested_new_node_id: requested_new_node_id,
        parent_node_id: parent_node_id,
        reference_type_node_id: reference_type_node_id,
        browse_name: browse_name,
        type_definition: type_definition
      )

      :ok = Server.write_node_write_mask(s_pid, requested_new_node_id, 0x3FFFFF)
      :ok = Server.write_node_access_level(s_pid, requested_new_node_id, 3)

      :ok = Server.start(s_pid)

      {:ok, %{s_pid: s_pid, parent_pid: parent_pid}}
    end

    def handle_write(write_event, %{parent_pid: parent_pid} = state) do
      send(parent_pid, write_event)
      state
    end
  end

  setup() do
    {:ok, _pid} = MyServer.start_link()

    {:ok, c_pid} = Client.start_link()
    :ok = Client.set_config(c_pid)
    :ok = Client.connect_by_url(c_pid, url: "opc.tcp://alde-Satellite-S845:4840/")

    %{c_pid: c_pid}
  end

  test "Write value event", %{c_pid: c_pid} do
    node_id =  NodeId.new(ns_index: 1, identifier_type: "integer", identifier: 10001)
    assert :ok == Client.write_node_value(c_pid, node_id, 0, true)
    c_response = Client.read_node_value(c_pid, node_id)
    assert c_response == {:ok, true}
    assert_receive({node_id, true}, 1000)
  end
end
