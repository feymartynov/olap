defmodule Olap.Formula.AST do
  defmodule Field do
    defstruct field: nil
  end

  defmodule Function do
    defstruct name: nil, signature: nil, impl: nil, args: []
  end
end
