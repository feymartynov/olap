defmodule Olap.Formula.AST do
  defmodule Constant do
    defstruct value: nil, type: nil
  end

  defmodule FunctionCall do
    defstruct mod: nil, args: []
  end
end
