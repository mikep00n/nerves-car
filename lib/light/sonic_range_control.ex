defmodule Light.SonicRangeControl do
  use GenServer
  require Logger
  @type position :: :left | :right | :up | :down

  @retry_count 20
  @microsecond_divisor 58

  # API

  @spec start_link(position) :: {:ok, pid}
  def start_link(position) do
    Genserver.start_link(Control, [], name: create_name(position))
  end

  defp create_name(position) do
    String.to_atom("control_server_#{position}")
  end

  def init(_) do
    {:ok, %{}}
  end
  Accessibility links
  Skip to main contentAccessibility help
  Accessibility feedback
  ￼
  ￼
  alias in elixir
  ￼
  Search modes
  AllShoppingVideosImagesNewsMore
  SettingsTools
  About 605,000 results (0.42 seconds)
  Search Results
  Web results
  alias, require, and import - Elixir
  https://elixir-lang.org/getting-started/alias-require-and-import.html
  alias. alias allows you to set up aliases for any given module name. The original List can still be accessed within Stats by the fully-qualified name Elixir.List . Note: All modules defined in Elixir are defined inside the main Elixir namespace.
  ‎alias · ‎require · ‎import · ‎use
  Elixir Aliases - Tutorialspoint
  https://www.tutorialspoint.com/elixir/elixir_aliases.htm
  Elixir - Aliases. alias. The alias directive allows you to set up aliases for any given module name. require. Elixir provides macros as a mechanism for meta-programming (writing code that generates code). import. We use the import directive to easily access functions or macros from other modules without using the fully ...
  A Module By Any Other Name: Aliases in Elixir | Hashrocket
  https://hashrocket.com/blog/posts/modules-and-aliases-in-elixir
  Apr 18, 2017 - A Module By Any Other Name: Aliases in Elixir. Modules provide a way for us to organize our code and compose complex systems. "A module is a collection of functions, something like a namespace. Every Elixir function must be defined inside a module.
  Understanding Aliases | Elixir - Getting Started - GitBook
  https://rokobasilisk.gitbooks.io/elixir-getting.../alias.../understanding_aliases.html
  An alias in Elixir is a capitalized identifier (like String , Keyword , etc) which is converted to an atom during compilation. For instance, the String alias translates by ...
  13 alias, require and import — Elixir documentation
  elixir-lang.readthedocs.io/en/latest/intro/13.html
  alias allows you to set up aliases for any given module name. ... List.flatten Note: All modules defined in Elixir are defined inside a main Elixir namespace.
  Use, import, require, what do they mean in Elixir? – Learning Elixir
  learningelixir.joekain.com/use-import-require-in-elixir/
  Jan 20, 2016 - There a several special forms for referring to other modules in Elixir. These include: use; import; require; alias. These each have their own ...
  Mix – Mix v1.7.4 - HexDocs
  https://hexdocs.pm/mix/Mix.html
  In the example above, we have defined an alias named mix all , that prints hello, then ... Aliases can be used very powerfully to also run Elixir scripts and bash ...
  module - Elixir alias on a submodule - Stack Overflow
  https://stackoverflow.com/questions/34104776/elixir-alias-on-a-submodule
  1 answer
  Aug 2, 2016 - This works only for the module in which the alias is defined, e.g.: defmodule A do alias A.B, as: C defmodule B do defstruct name: "" end def new do %C{} end ...
  Elixir Alias returns "invalid argument for alias, expected a ...	Dec. 31, 2017
  Elixir rename imported function to alias	Dec. 1, 2017
  Elixir: use vs import	Apr. 2, 2017
  Can I have an alias of function inside the same library in Elixir ...	May 1, 2016
  More results from stackoverflow.com
  5 Elixir tricks you should know - DockYard
  https://dockyard.com/blog/2017/08/15/elixir-tips
  Aug 15, 2017 - Now you know alias __MODULE__ just defines an alias for our Elixir module. This is very useful when used with defstruct which we will talk ...
  Module aliasing in macros - Questions / Help - Elixir Forum
  https://elixirforum.com/t/module-aliasing-in-macros/10644
  Dec 6, 2017 - Hi There is something I don't get about macros, modules and aliasing. Consider the following code snippets. Module Foo exports macro show/1 ...
  Searches related to alias in elixir
  elixir alias __module__

  elixir alias multiple

  elixir import module from file

  elixir nested modules

  elixir defdelegate

  elixir mix aliases

  elixir alias command

  elixir defstruct

  Page navigation
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  Next
  Footer links
  Canada V5M, Vancouver, BC - From your search history - Use precise location - Learn more
  HelpSend feedbackPrivacyTerms
  @spec find_echo_range(position, pid) :: integer
  def find_echo_range(position, reader_pin_pid) do
    GenServer.call(create_name(position), {:find_range, reader_pin_pid})
  end

  # Server

  def handle_call({:find_range, reader_pin_pid}, _from, state) do
    {:reply, find_range(reader_pin_pid), state}
  end

  defp find_range(reader_pin_pid) do

    case time_between_echo(reader_pin_pid) do
      0 -> 0
      microseconds -> microseconds / @microsecond_divisor / 2
    end

  end

  def safe_divisor(0), do: 1
  def safe_divisor(n), do: n

  def round_num(n) when is_float(n), do: trunc(Float.round(n))
  def round_num(n) when is_integer(n), do: n

  def time_between_echo(reader_pin_pid, start_time \\ NaiveDateTime.utc_now(), retry_count \\ 0) do
    if retry_count < @retry_count do
      case GPIO.read(reader_pin_pid) do
        0 -> time_between_echo(reader_pin_pid, start_time, retry_count + 1)
        1 -> save_when_returns_0(reader_pin_pid, start_time)
        _ -> raise RuntimeError, "Error reading pin"
      end
    else
      0
    end
  end

  def save_when_returns_0(reader_pin_pid, start_time, retry \\ 0) do
    cond do
      retry > @retry_count ->
        Logger.info("Unable to read echo return")

        0

      GPIO.read(reader_pin_pid) === 1 ->
        save_when_returns_0(reader_pin_pid, start_time, retry + 1)

      GPIO.read(reader_pin_pid) === 0 ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), start_time, :microseconds)
    end
  end

end
