// <!--
// The MIT License (MIT)
//
// Copyright (c) 2024 Kris Jusiak <kris@jusiak.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
#if 0
// -->
[Overview](#Overview) / [Examples](#Examples) / [API](#API) / [FAQ](#FAQ)

## SML: UML-2.5 State Machine Language

[![MIT Licence](http://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit)
[![Version](https://badge.fury.io/gh/qlibs%2Fut.svg)](https://github.com/qlibs/sml/releases)
[![build](https://img.shields.io/badge/build-blue.svg)](https://godbolt.org/z/Gcfncoo6r)
[![Try it online](https://img.shields.io/badge/try%20it-online-blue.svg)]()

  > https://en.wikipedia.org/wiki/Finite-state_machine

### Features

- Single header (https://raw.githubusercontent.com/qlibs/sml/main/sml - for integration see [FAQ](#faq))
- Verifies itself upon include (can be disabled with `-DNTEST` - see [FAQ](#faq))
- Optimized run-time execution, binary size, compilation-times (see [performance](https://godbolt.org/z/W9rP94cYK))
- Minimal [API](#api)

### Requirements

- C++20 ([Clang-15+, GCC-12+](https://en.cppreference.com/w/cpp/compiler_support))

  - No dependencies (Neither `Boost` nor `STL` is required)
  - No `virtual` used (-fno-rtti)
  - No `exceptions` required (-fno-exceptions)
  - `static_assert(1u == sizeof(State Machine))`

---

### Overview

> State Machine (https://godbolt.org/z/Yq7q3rhf7)

<p align="center"><img src="https://www.planttext.com/api/plantuml/png/RP313e9034Jl_OfwDK7l7Wo9_WKXPc4RQB8KmXQ-twAoIcHlpRoPQJUFwaQTke1rBqArSY-dGHeuQ4iTuSpLw4H1MGFXBJ40YCMnnFIox8ftZfyKygR_ZcZowfPcCLpMHZmZsHPLuDYQQqDzNHRnTYNsrR5HT-XXoIcGusDsWJsMrZPI9FtpxYoet54_xQARsmprQGR8IRpzA3m1" /></p>

```cpp
// events
struct connect {};
struct established {};
struct ping { bool valid{true}; };
struct disconnect {};
struct timeout {};

int main() {
  // guards/actions
  auto establish = [] { std::puts("establish"); };
  auto close     = [] { std::puts("close"); };
  auto reset     = [] { std::puts("reset"); };

  // states
  struct Disconnected {};
  struct Connecting {};
  struct Connected {};

  // transitions
  sml::sm connection = sml::overload{
    [](Disconnected, connect)     -> Connecting   { establish(); return {}; },
    [](Connecting,   established) -> Connected    { return {}; },
    [](Connected,    ping event)                  { if (event.valid) { reset(); } },
    [](Connected,    timeout)     -> Connecting   { establish(); return {}; },
    [](Connected,    disconnect)  -> Disconnected { close(); return {}; },
  };

  static_assert(sizeof(connection) == 1u);
  assert(connection.is<Disconnected>());

  assert(connection.process_event(connect{}));
  assert(connection.is<Connecting>());

  assert(connection.process_event(established{}));
  assert(connection.is<Connected>());

  assert(connection.process_event(ping{.valid = true}));
  assert(connection.is<Connected>());

  assert(connection.process_event(disconnect{}));
  assert(connection.is<Disconnected>());
}
```

```cpp
main: // $CXX -O3 -fno-exceptions -fno-rtti
  push    rax
  lea     rdi, [rip + .L.str.8]
  call    puts@PLT
  lea     rdi, [rip + .L.str.9]
  call    puts@PLT
  lea     rdi, [rip + .L.str.10]
  call    puts@PLT
  xor     eax, eax
  pop     rcx
  ret

.L.str.8:  .asciz  "establish"
.L.str.9:  .asciz  "reset"
.L.str.10: .asciz  "close"
```

---

### Examples

--

### API

---

### FAQ

- How to integrate with CMake/CPM?

    ```
    CPMAddPackage(
      Name sml
      GITHUB_REPOSITORY qlibs/sml
      GIT_TAG v3.0.0
    )
    add_library(sml INTERFACE)
    target_include_directories(sml SYSTEM INTERFACE ${sml_SOURCE_DIR})
    add_library(qlibs::sml ALIAS sml)
    ```

    ```
    target_link_libraries(${PROJECT_NAME} qlibs::sml);
    ```

- Acknowledgments

  > https://www.youtube.com/watch?v=Zb6xcd2as6o
<!--
#endif

#pragma once

namespace sml::inline v3_0_0 {
namespace type_traits {
struct none {};
template<class...> inline constexpr auto is_same_v = false;
template<class T> inline constexpr auto is_same_v<T, T> = true;
template<class T> struct remove_reference { using type = T; };
template<class T> struct remove_reference<T&> { using type = T; };
template<class T> struct remove_reference<T&&> { using type = T; };
template<class T> using remove_reference_t = typename remove_reference<T>::type;
template<class T> struct remove_cv { using type = T; };
template<class T> struct remove_cv<const T> { using type = T; };
template<class T> struct remove_cv<volatile T> { using type = T; };
template<class T> struct remove_cv<const volatile T> { using type = T; };
template<class T> using remove_cv_t = typename remove_cv<T>::type;
template<class T> using remove_cvref_t = remove_cv_t<remove_reference_t<T>>;
namespace detail {
template<bool> struct conditional;
template<> struct conditional<false> { template<class, class T> using fn = T; };
template<> struct conditional<true>  { template<class T, class> using fn = T; };
} // namespace detail
template<bool B, class T, class F>
struct conditional { using type = typename detail::conditional<B>::template fn<T, F>; };
template<bool B, class T, class F>
using conditional_t = typename detail::conditional<B>::template fn<T, F>;
template<class T> struct value_type { using type = T; };
template<class T> requires requires { typename T::value_type; } struct value_type<T> { using type = typename T::value_type; };
template<class> struct transition_traits;
template<class T> requires requires { &T::operator(); }
struct transition_traits<T> : transition_traits<decltype(&T::operator())> { };
template<class T> requires requires { &T::template operator()<none>; }
struct transition_traits<T> : transition_traits<decltype(&T::template operator()<none>)> { };
template<class T> requires requires { &T::template operator()<none, none>; }
struct transition_traits<T> : transition_traits<decltype(&T::template operator()<none, none>)> { };
template<class T, class TSrc, class TEvent, class TDst> struct transition_traits<auto (T::*)(TSrc, TEvent) const -> TDst> {
  using src = remove_cvref_t<TSrc>;
  using event = remove_cvref_t<TEvent>;
  using dst = typename value_type<remove_cvref_t<TDst>>::type;
};
template<class T, class TSrc, class TEvent, class TDst> struct transition_traits<auto (T::*)(TSrc, TEvent) -> TDst> {
  using src = remove_cvref_t<TSrc>;
  using event = remove_cvref_t<TEvent>;
  using dst = typename value_type<remove_cvref_t<TDst>>::type;
};
} // namespace type_traits
namespace mp {
template<class...> struct type_list {};
template<class... Ts> struct inherit : Ts... {};
template<class> struct wrapper {};
template<class...> struct unique;
template<class T, class... Ts, class... Rs>
struct unique<type_list<T, Ts...>, inherit<Rs...>> :
  type_traits::conditional_t<
    __is_same(T, void) or __is_same(T, type_traits::none) or __is_base_of(wrapper<T>, inherit<wrapper<Rs>...>),
    unique<type_list<Ts...>, inherit<Rs...>>,
    unique<type_list<Ts...>, inherit<Rs..., T>>
  > { };
template<class... Rs> struct unique<type_list<>, inherit<Rs...>> { using type = type_list<Rs...>; };
template<class... Ts> using unique_t = typename unique<type_list<Ts...>, inherit<>>::type;
template<template <class...> class, class> struct apply;
template<template <class...> class TList, template <class...> class T, class... Ts>
struct apply<TList, T<Ts...>> { using type = TList<Ts...>; };
template<template <class...> class TList, class T> using apply_t = typename apply<TList, T>::type;
} // namespace mp
namespace utility {
template<class T> auto declval() -> T&&;
template<class... Ts> requires (__is_empty(Ts) and ...)
struct variant {
  template<class T> constexpr variant(const T&) requires (type_traits::is_same_v<T, Ts> or ...)
    : index{[]() -> decltype(index) {
        bool match[]{type_traits::is_same_v<Ts, T>...};
        for (auto i = 0u; i < sizeof...(Ts); ++i) if (match[i]) return i;
        return {};
      }()} { }
  unsigned char index{};
};

template<class Fn, class... Ts>
[[nodiscard]] constexpr auto visit(Fn fn, const variant<Ts...>& v) {
  bool (*dispatch[])(Fn){[](Fn fn) { return fn(Ts{}); }...};
  return dispatch[v.index](fn);
}
} // namespace utility

struct X {}; /// terminate state

template<class T>
class sm {
  template<class R> struct value_type {
    using type = typename R::value_type;
  };
  template<class R> requires requires(R t) { t(); }
  struct value_type<R> {
    using type = typename type_traits::remove_cvref_t<decltype(utility::declval<R>()())>::value_type;
  };

  template<class... Ts> static auto unique_states(mp::type_list<Ts...>) ->
    mp::unique_t<typename type_traits::transition_traits<Ts>::src..., typename type_traits::transition_traits<Ts>::dst...>;

  template<class... Ts> static auto all_events(mp::type_list<Ts...>) ->
    mp::type_list<typename type_traits::transition_traits<Ts>::event...>;

  template<class... Ts> static auto unique_events(mp::type_list<Ts...>) ->
    mp::unique_t<typename type_traits::transition_traits<Ts>::event...>;

 public:
  using states = decltype(unique_states(typename value_type<T>::type{}));
  using events = decltype(unique_events(typename value_type<T>::type{}));

  template<class TEvent>
  static constexpr bool has_event = []<class... TEvents, class... Ts>(mp::type_list<TEvents...>, mp::type_list<Ts...>) {
    return (type_traits::is_same_v<Ts, type_traits::none> or ...) ? true : (type_traits::is_same_v<TEvents, TEvent> or ...);
  }(events{}, decltype(all_events(typename value_type<T>::type{})){});

  constexpr sm(const T& t) : t_{t} { }

  template<class TEvent> requires has_event<TEvent>
  constexpr auto process_event(const TEvent& event) -> bool {
    return utility::visit([&](const auto& state) {
      if constexpr (requires { states_ = *t_()(state, event); }) {
        if (auto r = t_()(state, event); r) {
          states_ = *r;
          return true;
        }
        return false;
      } else if constexpr (requires { states_ = t_()(state, event); }) {
        states_ = t_()(state, event);
        return true;
      } else  if constexpr (requires { t_()(state, event); }) {
        t_()(state, event);
        return true;
      } else if constexpr (requires { states_ = t_(state, event); }) {
        states_ = t_(state, event);
        return true;
      } else if constexpr (requires { states_ = *t_(state, event); }) {
        if (auto r = t_(state, event); r) {
          states_ = *r;
          return true;
        }
        return false;
      } else  if constexpr (requires { t_(state, event); }) {
        t_(state, event);
        return true;
      } else {
        return false;
      }
    }, states_);
  }

  template<class... TStates> [[nodiscard]] constexpr auto is() const -> bool {
    return utility::visit([&]<class TState>(const TState&) { return (type_traits::is_same_v<TStates, TState> and ...); }, states_);
  }

 private:
  [[no_unique_address]] T t_{};
  [[no_unique_address]] mp::apply_t<utility::variant, states> states_ =
    []<class TState, class... TStates>(const mp::type_list<TState, TStates...>&) { return TState{}; }(states{});
};

template<class... Ts> struct overload : Ts... {
  using value_type = mp::type_list<Ts...>;
  using Ts::operator()...;
};
template<class... Ts> overload(Ts...) -> overload<Ts...>;

template<class T> struct maybe {
  using value_type = T;
  constexpr maybe() = default;
  constexpr maybe(const T& t) : t{t}, flag{true} { }
  constexpr operator bool() const { return flag; }
  constexpr const T& operator*() const { return t; }
  T t{};
  bool flag{};
};
} // namespace sml

#ifndef NTEST
static_assert(([] {
  constexpr auto expect = [](bool cond) { if (not cond) { void failed(); failed(); } };

  /// states
  struct idle {};
  struct s1 {};
  struct s2 {};
  struct s3 {};
  struct s4 {};

  /// events
  struct e1 {};
  struct e2 {};
  struct e3 {};
  struct e { int value{}; };
  struct unexpected {};

  // sml::mp
  {
    using sml::mp::type_list;
    using sml::type_traits::is_same_v;

    // unique_t
    {
      static_assert(is_same_v<type_list<int>, sml::mp::unique_t<int>>);
      static_assert(is_same_v<type_list<int, double>, sml::mp::unique_t<int, double>>);
      static_assert(is_same_v<type_list<int>, sml::mp::unique_t<int, int>>);
    }
  }

  // sml::sm::process_event
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; }
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
  }

#if 0
  // start[on_entry]
  {
    int on_entry_calls{};

    sm sm = [&] {
      using namespace dsl;
      constexpr auto on_entry = dsl::on_entry;
      return transition_table{
          *"idle"_s + on_entry / [&] { ++on_entry_calls; }
      };
    };

    expect(sm.is<idle>());
    expect(on_entry_calls == 1);
  }

  // process_event[on_entry/on_exit]
  {
    int on_entry_calls{};
    int on_exit_calls{};

    sm sm = [&] {
      using namespace dsl;
      constexpr auto on_entry = dsl::on_entry;
      constexpr auto on_exit = dsl::on_exit;
      return transition_table{
          *"s1"_s + event<e1> = "s2"_s,
           "s2"_s + on_entry / [&] { ++on_entry_calls; },
           "s2"_s + on_exit / [&] { ++on_exit_calls; },
           "s2"_s + event<e2> = "s3"_s,
      };
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(sm.process_event(e2{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 1);
    expect(sm.is<s3>());
  }

  // process_event[on_entry/on_exit] with internal transitions
  {
    int on_entry_calls{};
    int on_exit_calls{};

    sm sm = [&] {
      using namespace dsl;
      constexpr auto on_entry = dsl::on_entry;
      constexpr auto on_exit = dsl::on_exit;
      return transition_table{
          *"s1"_s + event<e1> = "s2"_s,
           "s2"_s + event<e2>,
           "s2"_s + on_entry / [&] { ++on_entry_calls; },
           "s2"_s + on_exit / [&] { ++on_exit_calls; },
      };
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(sm.process_event(e2{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(sm.is<s2>());
  }
#endif

  // process_event[same event multiple times]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
      [](s2, e1) -> s3 { return {}; },
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s3>());
  }

  // process_event[different events in any state]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
      [](s2, e2) -> s3 { return {}; },
      [](s3, e2) -> sml::X { return {}; },
      [](auto, e) -> s1 { return {}; },
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());

    expect(sm.process_event(e{{}}));
    expect(sm.is<s1>());
    expect(not sm.process_event(e2{}));  // ignored
    expect(sm.is<s1>());

    expect(sm.process_event(e1{}));  // s1 -> s2
    expect(sm.is<s2>());

    expect(sm.process_event(e2{}));  // s2 -> s3
    expect(sm.is<s3>());

    expect(sm.process_event(e{}));  // _ -> s1
    expect(sm.is<s1>());
  }

  // proces_event[unexpected event]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
    };

    constexpr auto process_event = [](const auto& event) {
      return requires { sm.process_event(event); };
    };

    static_assert(process_event(e1{}));
    static_assert(not process_event(unexpected{}));
  }

  // events[multiple events]
  {
    sml::sm test = sml::overload{
      [](s1, auto) -> s2 { return {}; },
    };

    {
      sml::sm sm{test};
      expect(sm.is<s1>());
      expect(sm.process_event(e1{}));
      expect(sm.is<s2>());
    }

    {
      sml::sm sm{test};
      expect(sm.is<s1>());
      expect(sm.process_event(e2{}));
      expect(sm.is<s2>());
    }
  }

  // events[same event transitions]
  {
    sml::sm sm = sml::overload{
      [](idle, e1) -> s1 { return {}; },
      [](s1, e1) -> s2 { return {}; },
      [](s2, e1) -> idle { return {}; },
    };

    expect(sm.is<idle>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s1>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(sm.process_event(e1{}));
    expect(sm.is<idle>());
  }

  // transition_table[multiple transitions]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
      [](s2, e2) -> s1 { return {}; },
    };

    expect(sm.is<s1>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(not sm.process_event(e1{}));
    expect(sm.is<s2>());
    expect(sm.process_event(e2{}));
    expect(sm.is<s1>());
  }

  // transition_table[terminated state]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> sml::X { return {}; },
    };

    expect(sm.is<s1>());
    expect(sm.process_event(e1{}));
    expect(sm.is<sml::X>());
    expect(not sm.process_event(e1{}));
  }

  // transition_table[guards/actions]
  {
    unsigned calls{};

    auto guard = [](const auto& event) { return event.value; };
    auto action = [&] { ++calls; };

    sml::sm sm = sml::overload{
      [&](s1, const e& event) -> sml::maybe<s2> {
        if (guard(event)) {
          action();
          return s2{};
        }
        return {};
      },
    };

    expect(not sm.process_event(e{false}));
    expect(sm.is<s1>());
    expect(sm.process_event(e{true}));
    expect(sm.is<s2>());
  }

#if 0
  // transition_table[process]
  {
    sm sm = [] {
      using namespace dsl;
      return transition_table{
          *"s1"_s + event<e1> / process(e2{}) = "s2"_s,
          "s2"_s + event<e2> = "s3"_s,
      };
    };

    expect(sm.process_event(e1{}));
    expect(sm.is<s3>());
  }

  // transition_table[orthogonal regions]
  {
    sml::sm sm = sml::overload{
      sml::overload{
        [](s1, e1) -> s2 { return {}; },
      },
      sml::overload{
        [](s3, e2) -> s4 { return {}; },
      }
    };

    expect(sm.is<s1, s3>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s2, s3>());
    expect(sm.process_event(e2{}));
    expect(sm.is<s2, s4>());
  }

  // transition_table[orthogonal regions]
  {
    using sml::X;

    sml::sm sm = sml::overload{
      sml::overload{
        [](s1, e1) -> s2 { return {}; },
        [](s2, e2) -> X  { return {}; },
      },
      sml::overload{
        [](s3, e3) -> X  { return {}; },
      }
    };

    expect(sm.is<s1, s3>());
    expect(sm.process_event(e1{}));
    expect(sm.is<s2, s3>());
    expect(sm.process_event(e2{}));
    expect(sm.is<X, s3>());
    expect(sm.process_event(e3{}));
    expect(sm.is<X, X>());
  }
#endif

  // dependencies
  {
    struct s {
      bool value{};
      constexpr auto guard() { return value; };
      constexpr auto operator()() {
        return sml::overload{
          [this](s1, e1) -> sml::maybe<s2> { if (guard()) return s2{}; return {}; },
        };
      }
    };

    {
      sml::sm sm{s{}};
      expect(not sm.process_event(e1{}));
      expect(sm.is<s1>());
    }

    {
      s s{true};
      sml::sm sm{s};
      expect(sm.process_event(e1{}));
      expect(sm.is<s2>());
    }
  }

  // example.connection
  {
    struct connect {};
    struct established {};
    struct ping { bool valid{true}; };
    struct disconnect {};
    struct timeout {};

    {
      struct sm {
        /// states
        struct Disconnected {};
        struct Connecting {};
        struct Connected {};

        /// guards/actions
        constexpr void establish(){}
        constexpr void close(){}
        constexpr void reset_timeout(){ }

        /// transitions
        constexpr auto operator()() {
          return sml::overload{
            [this](Disconnected, connect)            -> Connecting   { establish(); return {}; },
            [    ](Connecting,   established)        -> Connected    { return {}; },
            [this](Connected,    const ping& event)                  { if (event.valid) { reset_timeout(); } },
            [this](Connected,    timeout)            -> Connecting   { establish(); return {}; },
            [this](Connected,    disconnect)         -> Disconnected { close(); return {}; },
          };
        }
      };

      sml::sm connection{sm{}};

      struct empty{};
      static_assert(sizeof(connection) == sizeof(empty));
      expect(connection.is<sm::Disconnected>());
      expect(connection.process_event(connect{}));
      expect(connection.is<sm::Connecting>());
      expect(connection.process_event(established{}));
      expect(connection.is<sm::Connected>());
      expect(connection.process_event(ping{.valid = true}));
      expect(connection.is<sm::Connected>());
      expect(connection.process_event(disconnect{}));
      expect(connection.is<sm::Disconnected>());
    }

    #if __cpp_constexpr >= 202211L
    {
      struct sm {
        /// states
        struct Disconnected {};
        struct Connecting {};
        struct Connected {};

        static constexpr void establish(){}
        static constexpr void close(){}
        static constexpr void reset_timeout(){ }

        /// transitions
        constexpr auto operator()() const {
          return sml::overload{
            [](Disconnected, connect)            -> Connecting   { establish(); return {}; },
            [](Connecting,   established)        -> Connected    { return {}; },
            [](Connected,    const ping& event)                  { if (event.valid) { reset_timeout(); } },
            [](Connected,    timeout)            -> Connecting   { establish(); return {}; },
            [](Connected,    disconnect)         -> Disconnected { close(); return {}; },
          };
        }
      };

      sml::sm connection{sm{}};

      struct empty{};
      static_assert(sizeof(connection) == sizeof(empty));
      expect(connection.is<sm::Disconnected>());
      expect(connection.process_event(connect{}));
      expect(connection.is<sm::Connecting>());
      expect(connection.process_event(established{}));
      expect(connection.is<sm::Connected>());
      expect(connection.process_event(ping{.valid = true}));
      expect(connection.is<sm::Connected>());
      expect(connection.process_event(disconnect{}));
      expect(connection.is<sm::Disconnected>());
    }

    {
      struct Disconnected {};
      struct Connecting {};
      struct Connected {};

      static constexpr auto establish = []{};
      static constexpr auto close = []{ };
      static constexpr auto reset_timeout = []{ };

      sml::sm connection = sml::overload{
        [](Disconnected, connect)            -> Connecting   { establish(); return {}; },
        [](Connecting,   established)        -> Connected    { return {}; },
        [](Connected,    const ping& event)                  { if (event.valid) { reset_timeout(); } },
        [](Connected,    timeout)            -> Connecting   { establish(); return {}; },
        [](Connected,    disconnect)         -> Disconnected { close(); return {}; },
      };

      struct empty{};
      static_assert(sizeof(connection) == sizeof(empty));
      expect(connection.is<Disconnected>());
      expect(connection.process_event(connect{}));
      expect(connection.is<Connecting>());
      expect(connection.process_event(established{}));
      expect(connection.is<Connected>());
      expect(connection.process_event(ping{.valid = true}));
      expect(connection.is<Connected>());
      expect(connection.process_event(disconnect{}));
      expect(connection.is<Disconnected>());
    }
    #endif
  }
}(), true));
#endif // NTEST
