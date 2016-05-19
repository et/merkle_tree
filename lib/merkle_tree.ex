defmodule MerkleTree do
  @moduledoc """
    A hash tree or Merkle tree is a tree in which every non-leaf node is labelled
    with the hash of the labels or values (in case of leaves) of its child nodes.
    Hash trees are useful because they allow efficient and secure verification of
    the contents of large data structures.

    ## Usage Example

      iex> f = MerkleTree.new ['a', 'b', 'c', 'd']
      %MerkleTree{blocks: ['a', 'b', 'c', 'd'], hash_function: &MerkleTree.Crypto.sha256/1,
            root: %MerkleTree.Node{children: [%MerkleTree.Node{children: [%MerkleTree.Node{children: [],
                 value: "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"},
                %MerkleTree.Node{children: [], value: "3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d"}],
               value: "62af5c3cb8da3e4f25061e829ebeea5c7513c54949115b1acc225930a90154da"},
              %MerkleTree.Node{children: [%MerkleTree.Node{children: [], value: "2e7d2c03a9507ae265ecf5b5356885a53393a2029d241394997265a1a25aefc6"},
                %MerkleTree.Node{children: [], value: "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"}],
               value: "d3a0f1c792ccf7f1708d5422696263e35755a86917ea76ef9242bd4a8cf4891a"}],
             value: "58c89d709329eb37285837b042ab6ff72c7c8f74de0446b091b6a0131c102cfd"}}
  """

  defstruct [:blocks, :root, :hash_function]

  @type blocks :: [String.t, ...]
  @type hash_function :: (String.t -> String.t)
  @type root :: MerkleTree.Node.t
  @type t :: %MerkleTree{
    blocks: blocks,
    root: root,
    hash_function: hash_function
  }

  @doc """
    Creates a new merkle tree, given a 2^N number of string blocks and an
    optional hash function.

    By default, merkle_tree uses :sha256 from :crypto.
    Check out MerkleTree.Crypto for other available cryptographic hashes.
    Alternatively, you can supply your own hash function that has the spec
    (String.t -> String.t).
  """
  @spec new(blocks, hash_function) :: t
  def new(blocks, hash_function \\ &MerkleTree.Crypto.sha256/1) do
    unless is_power_of_2(Enum.count(blocks)), do: raise MerkleTree.ArgumentError

    root = build(blocks, hash_function)
    %MerkleTree{blocks: blocks, hash_function: hash_function, root: root}
  end

  @doc """
    Builds a new binary merkle tree.
  """
  @spec new(blocks, hash_function) :: root
  def build(blocks, hash_function) do
    leaves = Enum.map(blocks, fn(block) ->
      %MerkleTree.Node{
        value: hash_function.(block),
        children: [],
      }
    end)
    build_tree(leaves, hash_function)
  end

  defp build_tree([root], _), do: root # Base case
  defp build_tree(nodes, hash_function) do # Recursive case
    children_pairs = Enum.chunk(nodes, 2)
    parents = Enum.map(children_pairs, fn([left, right] = pair) ->
      %MerkleTree.Node{
        value: hash_function.(left.value <> right.value),
        children: pair
      }
    end)
    build_tree(parents, hash_function)
  end

  @spec is_power_of_2(pos_integer) :: boolean
  def is_power_of_2(n) do
    n |> :math.log2 |> is_integer_float
  end

  @spec is_integer_float(float) :: boolean
  def is_integer_float(n) do
    (Float.ceil n) == (Float.floor n)
  end
end
