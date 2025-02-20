defmodule Ash.Resource.Actions.SharedOptions do
  @moduledoc false

  @shared_options [
    name: [
      type: :atom,
      required: true,
      doc: "The name of the action"
    ],
    as: [
      type: :atom,
      doc:
        "Overwrite the name of the helper function added onto the Api module. The helper defaults to <resource_name>_<action_name>"
    ],
    primary?: [
      type: :boolean,
      default: false,
      doc: "Whether or not this action should be used when no action is specified by the caller."
    ],
    description: [
      type: :string,
      doc: "An optional description for the action"
    ]
  ]

  @create_update_opts [
    accept: [
      type: {:custom, Ash.OptionsHelpers, :list_of_atoms, []},
      doc:
        "The list of attributes and relationships to accept. Defaults to all attributes on the resource"
    ],
    reject: [
      type: {:custom, Ash.OptionsHelpers, :list_of_atoms, []},
      doc: """
      A list of attributes and relationships not to accept. This is useful if you want to say 'accept all but x'

      If this is specified along with `accept`, then everything in the `accept` list minuse any matches in the
      `reject` list will be accepted.
      """
    ]
  ]

  def shared_options do
    @shared_options
  end

  def create_update_opts do
    @create_update_opts
  end
end
