defmodule Rummage.Ecto.Services.BuildSearchQuery do
  @moduledoc """
  `Rummage.Ecto.Services.BuildSearchQuery` is a service module which serves the
  default search hook, `Rummage.Ecto.Hooks.Search` that comes shipped with `Rummage.Ecto`.

  Has a `Module Attribute` called `search_types`:

  ```elixir
  @search_types ~w(like ilike eq gt lt gteq lteq)
  ```

  `@search_types` is a collection of all the 7 valid `search_types` that come shipped with
  `Rummage.Ecto`'s default search hook. The types are:

  * `like`: Searches for a `term` in a given `field` of a `queryable`.
  * `ilike`: Searches for a `term` in a given `field` of a `queryable`, in a case insensitive fashion.
  * `eq`: Searches for a `term` to be equal to a given `field` of a `queryable`.
  * `gt`: Searches for a `term` to be greater than to a given `field` of a `queryable`.
  * `lt`: Searches for a `term` to be less than to a given `field` of a `queryable`.
  * `gteq`: Searches for a `term` to be greater than or equal to to a given `field` of a `queryable`.
  * `lteq`: Searches for a `term` to be less than or equal to a given `field` of a `queryable`.

  Feel free to use this module on a custom search hook that you write.
  """

  import Ecto.Query

  @search_types ~w(like ilike eq gt lt gteq lteq daterange)

  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field`, `search_type`
  and `search_term`.

  ## Examples
  When `field`, `search_type` and `queryable` are passed with `search_type` of `like`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "like", "field_!", false)
      #Ecto.Query<from p in "parents", where: like(p.field_1, ^"%field_!%")>

  When `field`, `search_type` and `queryable` are passed with `search_type` of `ilike`:

        iex> alias Rummage.Ecto.Services.BuildSearchQuery
        iex> import Ecto.Query
        iex> queryable = from u in "parents"
        #Ecto.Query<from p in "parents">
        iex> BuildSearchQuery.run(queryable, :field_1, "ilike", "field_!", false)
        #Ecto.Query<from p in "parents", where: ilike(p.field_1, ^"%field_!%")>

  When `field`, `search_type` and `queryable` are passed with `search_type` of `eq`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "eq", "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 == ^"field_!">

  When `field`, `search_type` and `queryable` are passed with `search_type` of `gt`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "gt", "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 > ^"field_!">

  When `field`, `search_type` and `queryable` are passed with `search_type` of `lt`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "lt", "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 < ^"field_!">

 When `field`, `search_type` and `queryable` are passed with `search_type` of `gteq`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "gteq", "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 >= ^"field_!">

 When `field`, `search_type` and `queryable` are passed with `search_type` of `lteq`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "lteq", "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 <= ^"field_!">

When `field`, `search_type` and `queryable` are passed with an invalid `search_type`:

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.run(queryable, :field_1, "pizza", "field_!", false)
      #Ecto.Query<from p in "parents">
  """
  @spec run(Ecto.Query.t, atom, String.t, term, boolean) :: {Ecto.Query.t}
  def run(queryable, field, search_type, search_term, bind_to_base) do
    case Enum.member?(@search_types, search_type) do
      true -> apply(__MODULE__, String.to_atom("handle_" <> search_type), [queryable, field, search_term, bind_to_base])
      _ -> queryable
    end
  end

  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `like`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_like(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: like(p.field_1, ^"%field_!%")>
  """
  @spec handle_like(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_like(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      like(field(b, ^field), ^"%#{String.replace(search_term, "%", "\\%")}%"))
  end
  def handle_like(queryable, field, search_term, true) do
    queryable
    |> where([b],
      like(field(b, ^field), ^"%#{String.replace(search_term, "%", "\\%")}%"))
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `ilike`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_ilike(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: ilike(p.field_1, ^"%field_!%")>
  """
  @spec handle_ilike(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_ilike(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      ilike(field(b, ^field), ^"%#{String.replace(search_term, "%", "\\%")}%"))
  end
  def handle_ilike(queryable, field, search_term, true) do
    queryable
    |> where([b],
      ilike(field(b, ^field), ^"%#{String.replace(search_term, "%", "\\%")}%"))
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `eq`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_eq(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 == ^"field_!">
  """
  @spec handle_eq(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_eq(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      field(b, ^field) == ^search_term)
  end
  def handle_eq(queryable, field, search_term, true) do
    queryable
    |> where([b],
      field(b, ^field) == ^search_term)
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `gt`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_gt(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 > ^"field_!">
  """
  @spec handle_gt(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_gt(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      field(b, ^field) > ^search_term)
  end
  def handle_gt(queryable, field, search_term, true) do
    queryable
    |> where([b],
      field(b, ^field) > ^search_term)
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `lt`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_lt(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 < ^"field_!">
  """
  @spec handle_lt(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_lt(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      field(b, ^field) < ^search_term)
  end
  def handle_lt(queryable, field, search_term, true) do
    queryable
    |> where([b],
      field(b, ^field) < ^search_term)
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `gteq`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_gteq(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 >= ^"field_!">
  """
  @spec handle_gteq(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_gteq(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      field(b, ^field) >= ^search_term)
  end
  def handle_gteq(queryable, field, search_term, true) do
    queryable
    |> where([b],
      field(b, ^field) >= ^search_term)
  end


  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `lteq`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_lteq(queryable, :field_1, "field_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 <= ^"field_!">
  """
  @spec handle_lteq(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_lteq(queryable, field, search_term, false) do
    queryable
    |> where([..., b],
      field(b, ^field) <= ^search_term)
  end
  def handle_lteq(queryable, field, search_term, true) do
    queryable
    |> where([b],
      field(b, ^field) <= ^search_term)
  end

  @doc """
  Builds a searched `queryable` on top of the given `queryable` using `field` and `search_type`
  when the `search_term` is `daterange`.

  ## Examples

      iex> alias Rummage.Ecto.Services.BuildSearchQuery
      iex> import Ecto.Query
      iex> queryable = from u in "parents"
      #Ecto.Query<from p in "parents">
      iex> BuildSearchQuery.handle_daterange(queryable, :field_1, "val1_!|val2_!", false)
      #Ecto.Query<from p in "parents", where: p.field_1 >= ^"val1_!" and p.field_1 <= ^"val2_!">
  """
  @spec handle_daterange(Ecto.Query.t, atom, term, boolean) :: {Ecto.Query.t}
  def handle_daterange(queryable, field, search_term, false) do
    [from, to] = String.split(search_term, "|")
    |> Enum.map(&NaiveDateTime.from_iso8601!(&1))

    queryable
    |> where([..., b],
      field(b, ^field) >= ^from and field(b, ^field) <= ^to)
  end
  def handle_daterange(queryable, field, search_term, true) do
    [from, to] = String.split(search_term, "|")
    |> Enum.map(&NaiveDateTime.from_iso8601!(&1))

    queryable
    |> where([b],
      field(b, ^field) >= ^from and field(b, ^field) <= ^to)
  end
end
