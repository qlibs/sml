<a href="http://www.boost.org/LICENSE_1_0.txt" target="_blank">![Boost Licence](http://img.shields.io/badge/license-boost-blue.svg)</a>
<a href="https://github.com/boost-ext/sml2/releases" target="_blank">![Version](https://badge.fury.io/gh/boost-ext%2Fsml2.svg)</a>
<a href="https://godbolt.org/z/eorGK5sEW">![build](https://img.shields.io/badge/build-blue.svg)</a>
<a href="https://godbolt.org/z/j51Tch6PT">![Try it online](https://img.shields.io/badge/try%20it-online-blue.svg)</a>

---------------------------------------

### SML2 (UML-2.5 State Machine Language)

- Single header (https://raw.githubusercontent.com/boost-ext/sml2/main/sml2)
    - Easy integration (see [FAQ](#faq))
- Verifies itself upon include (aka run all tests via static_asserts but it can be disabled - see [FAQ](#faq))
* Optimized run-time execution and binary size (see [performance](https://godbolt.org/z/W9rP94cYK))
* Fast compilation times (see [benchmarks](https://github.com/boost-ext/sml2/blob/gh-pages/images/sml2.perf.png))
* Declarative Domain Specific Language (see [API](#api))

### Requirements

- C++20 ([Clang-15+, GCC-12+](https://godbolt.org/z/eorGK5sEW))

    - No dependencies (Neither Boost nor STL is required)
    - No `virtual` used (-fno-rtti)
    - No `exceptions` required (-fno-exceptions)

---

<p align="center"><img src="https://github.com/boost-ext/sml2/blob/gh-pages/images/example.png" /></p>

```cpp
// events
struct connect {};
struct ping { bool valid = false; };
struct established {};
struct timeout {};
struct disconnect {};

int main() {
  // state machine
  sml::sm connection = [] {
    // guards
    auto is_valid  = [](const auto& event) { return event.valid; };

    // actions
    auto establish = [] { std::puts("establish"); };
    auto close     = [] { std::puts("close"); };
    auto setup     = [] { std::puts("setup"); };

    using namespace sml::dsl;
    /**
     * src_state + event [ guard ] / action = dst_state
     */
    return transition_table{
      *"Disconnected"_s + event<connect> / establish    = "Connecting"_s,
       "Connecting"_s   + event<established>            = "Connected"_s,
       "Connected"_s    + event<ping>[is_valid] / setup,
       "Connected"_s    + event<timeout> / establish    = "Connecting"_s,
       "Connected"_s    + event<disconnect> / close     = "Disconnected"_s,
    };
  };

  connection.process_event(connect{});
  connection.process_event(established{});
  connection.process_event(ping{.valid = true});
  connection.process_event(disconnect{});
}
```

---

### FAQ

- Why would I use a state machine?

    > State machine helps with understanding of the application flow as well as with avoiding spaghetti code.
      The more booleans/enums/conditions there are the harder is to understand the implicit state of the program.
      State machines make the state explicit which makes the code easier to follow,change and maintain.
      It's worth noticing that state machines are not required by any means (there is no silver bullet),
      switch-case, if-else, co-routines, state pattern, etc. can be used instead. Use your own judgment and
      experience when choosing a solution based its trade-offs.

- What UML2.5 features are supported and what features will be supported?

    > ATM `SML2` supports basic UML features such as transitions, processing events, unexpected events, etc.
      Please follow tests/examples to stay up to date with available features - https://github.com/boost-ext/sml2/blob/main/sml2#L388
      There is plan to add more features, potentially up to full UML-2.5 support.

- How does it compare to implementing state machines with co-routines?

   > It's a different approach. Either has its pros and cons. Co-routines are easier to be executed in parallel but they have performance overhead.
     Co-routines based state machines are written in imperative style whilst SML is using declarative Domain Specific Language (DSL).
     More information can be found here - https://youtu.be/Zb6xcd2as6o?t=1529

- SML vs UML?

    > `SML2` follows UML-2.5 - http://www.omg.org/spec/UML/2.5 - as closeily as possible but it has limited features ATM.
      More information can be found here - https://boost-ext.github.io/sml/uml_vs_sml.html

- Can I use `SML2` at compile-time?

    > Yes. `SML2` is fully compile-time but it can be executed at run-time as well. The run-time is primary use case for `SML2`.

- Can I disable running tests at compile-time for faster compilation times?

    > When `NTEST` is defined static_asserts tests won't be executed upon inclusion.
    Note: Use with caution as disabling tests means that there are no guarantees upon inclusion that the given compiler/env combination works as expected.

- Is `SML2` SFINAE friendly?

    > Yes, `SML2` is SFINAE (Substitution Failure Is Not An Error) friendly, especially the call to `process_event`.

- Should I switch to `SML2` from `SML`?

    > It depends. `SML2` is a different project and not as feature reach and production ready as SML and it requires C++20, however it compiles much faster.

- Where can I find/execute benchmarks?

    > Benchmarks can be found here - https://github.com/boost-ext/sml/tree/master/benchmark

- How to pass dependencies to guards/actions?

    ```cpp
    struct foo {
      bool value{};

      constexpr auto operator()() const {
        auto guard = [this] { return value; }; // dependency capctured by this
        return transition_table{
            *"s1"_s + event<e1>[guard] = "s2"_s,
        };
      }
    };

    sml::sm sm{foo{.value = 42}); // inject value into foo
    ```

- Is `SML2 suitable for embedded systems?

    > Yes, same as SML, `SML2` doesn't have any extenal dependencies, compiles without RTTI and without exceptions.
      It's also focused on performance, binary size and memory footprint.
      The following command compiiles without issues:
      `$CXX -std=c++20 -Ofast -fno-rtti -fno-exceptions -Wall -Wextra -Werror -pedantic -pedantic-errors example.cpp`

- How to integrate with CMake/CPM?

    ```
    CPMAddPackage(
      Name sml2
      GITHUB_REPOSITORY boost-ext/sml2
      GIT_TAG v2.0.0
    )
    add_library(sml2 INTERFACE)
    target_include_directories(sml2 SYSTEM INTERFACE ${sml2_SOURCE_DIR})
    add_library(sml2::sml2 ALIAS sml2)
    ```

    ```
    target_link_libraries(${PROJECT_NAME} sml2::sml2);
    ```

- Is there a Rust version?

    > Rust - `SML2` version can be found here - https://gist.github.com/krzysztof-jusiak/079f80e9d8c472b2c8d515cbf07ad665
