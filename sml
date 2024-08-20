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
[![Version](https://img.shields.io/github/v/release/qlibs/sml)](https://github.com/qlibs/sml/releases)
[![Build](https://img.shields.io/badge/build-green.svg)](https://godbolt.org/z/Gcfncoo6r)
[![Try it online](https://img.shields.io/badge/try%20it-online-blue.svg)](https://godbolt.org/z/s9a6EW5j9)

  > https://en.wikipedia.org/wiki/Finite-state_machine

  > https://www.omg.org/spec/UML/2.5.1

### Features

- Single header (https://raw.githubusercontent.com/qlibs/sml/main/sml - for integration see [FAQ](#faq))
- Verifies itself upon include (can be disabled with `-DNTEST` - see [FAQ](#faq))
- Optimized run-time execution, binary size, compilation-times (see [performance](https://godbolt.org/z/W9rP94cYK))
- Minimal [API](#api)

### Requirements

- C++20 ([Clang-15+, GCC-12+](https://en.cppreference.com/w/cpp/compiler_support))

  - No dependencies (no `#include/#import`)
  - No `virtual` used (`-fno-rtti`)
  - No `exceptions` required (`-fno-exceptions`)

---

### Overview

> State Machine (https://godbolt.org/z/s9a6EW5j9)

<p align="center"><img src="https://www.planttext.com/api/plantuml/png/RP313e9034Jl_OfwDK7l7Wo9_WKXPc4RQB8KmXQ-twAoIcHlpRoPQJUFwaQTke1rBqArSY-dGHeuQ4iTuSpLw4H1MGFXBJ40YCMnnFIox8ftZfyKygR_ZcZowfPcCLpMHZmZsHPLuDYQQqDzNHRnTYNsrR5HT-XXoIcGusDsWJsMrZPI9FtpxYoet54_xQARsmprQGR8IRpzA3m1" /></p>

```cpp
// events
struct connect {};
struct established {};
struct ping { bool valid{}; };
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
    [](Disconnected, const connect&)      -> Connecting   { establish(); },
    [](Connecting,   const established&)  -> Connected    { },
    [](Connected,    const ping& event)                   { if (event.valid) { reset(); } },
    [](Connected,    const timeout&)      -> Connecting   { establish(); },
    [](Connected,    const disconnect&)   -> Disconnected { close(); },
  };

  static_assert(sizeof(connection) == 1u);

  assert(connection.visit(is<Disconnected>));

  assert(connection.process_event(connect{}));
  assert(connection.visit(is<Connecting>));

  assert(connection.process_event(established{}));
  assert(connection.visit(is<Connected>));

  assert(connection.process_event(ping{.valid = true}));
  assert(connection.visit(is<Connected>));

  assert(connection.process_event(disconnect{}));
  assert(connection.visit(is<Disconnected>));
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

```cpp
template<class T>
  requires (requires (T t) { t(); })
struct sm {
  constexpr sm(T&&);
  template<class TEvent, auto dispatch = if_else>
    requires dispatchable<TEvent>
  constexpr auto process_event(const TEvent& event) -> bool ;
  constexpr auto visit(auto&& fn) const;
};
```

```cpp
template<class... Ts> struct overload;
inline constexpr auto if_else; // if_else dispatch policy
inline constexpr auto jmp_table; // jmp_table dispatch policy
struct X {}; // terminate state
```

---

### FAQ

- How to integrate with [CMake.FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)?

    ```
    include(FetchContent)

    FetchContent_Declare(
      qlibs.sml
      GIT_REPOSITORY https://github.com/qlibs/sml
      GIT_TAG v3.0.0
    )

    FetchContent_MakeAvailable(qlibs.sml)
    ```

    ```
    target_link_libraries(${PROJECT_NAME} PUBLIC qlibs.sml);
    ```

- Acknowledgments

  > https://www.youtube.com/watch?v=Zb6xcd2as6o

- Similar projects?
    > [boost.msm](https://github.com/boostorg/msm), [boost.statechart](https://github.com/boostorg/statechart), [boost-ext.sml](https://github.com/boost-ext/sml)
<!--
#endif

#pragma once
#pragma GCC system_header

namespace sml::inline v3_0_0 {
using size_t = decltype(sizeof(int));
namespace type_traits {
struct none {};
template<class...> inline constexpr bool is_same_v = false;
template<class T> inline constexpr bool is_same_v<T, T> = true;
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
  using dst = remove_cvref_t<TDst>;
};
template<class T, class TSrc, class TEvent, class TDst> struct transition_traits<auto (T::*)(TSrc, TEvent) -> TDst> {
  using src = remove_cvref_t<TSrc>;
  using event = remove_cvref_t<TEvent>;
  using dst = remove_cvref_t<TDst>;
};
} // namespace type_traits
namespace utility {
template<class T> auto declval() -> T&&;
template<class T, T...> struct integer_sequence { };
template<size_t... Ns> using index_sequence = integer_sequence<size_t, Ns...>;
template<size_t N> using make_index_sequence =
#if defined(__clang__) || defined(_MSC_VER)
  __make_integer_seq<integer_sequence, size_t, N>;
#else
   index_sequence<__integer_pack(N)...>;
#endif
template<class T> struct wrapper {
  [[no_unique_address]] T t;
  constexpr const auto& operator()() const { return t; }
};
} // namespace utility
namespace mp {
template<class...> struct type_list {};
using info = const size_t*;
template<info> struct meta_type { constexpr auto friend get(meta_type); };
template<class T> struct meta_info {
  using value_type = T;
  static constexpr size_t id{};
  constexpr auto friend get(meta_type<&id>) { return meta_info{}; }
};
template<class T> inline constexpr auto meta = &meta_info<T>::id;
template<info meta> using type_of = typename decltype(get(meta_type<meta>{}))::value_type;
template<template<class...> class T, const auto& v>
constexpr auto apply() {
  return []<size_t... Ns>(utility::index_sequence<Ns...>) {
    return T<type_of<v[Ns]>...>{};
  }(utility::make_index_sequence<v.size()>{});
}
template<template<class...> class T, const auto& v>
using apply_t = decltype(apply<T, v>());
} // namespace mp

template<class T, size_t N>
struct static_vector {
  constexpr static_vector() = default;
  constexpr auto push_back(const T& value) { values_[size_++] = value; }
  [[nodiscard]] constexpr const auto& operator[](auto i) const { return values_[i]; }
  [[nodiscard]] constexpr auto begin() const { return &values_[0]; }
  [[nodiscard]] constexpr auto end() const { return &values_[0] + size_; }
  [[nodiscard]] constexpr auto size() const { return size_; }
  [[nodiscard]] constexpr auto empty() const { return not size_; }
  [[nodiscard]] constexpr auto capacity() const { return N; }
  T values_[N]{};
  size_t size_{};
};

template<class... Ts>
  requires (__is_empty(Ts) and ...) and (sizeof...(Ts) < (1u << __CHAR_BIT__))
struct variant {
  template<class T> static constexpr auto id = [] {
    const bool match[]{type_traits::is_same_v<Ts, T>...};
    for (auto i = 0; i < sizeof...(Ts); ++i) if (match[i]) return i;
    return -1;
  }();

  constexpr variant() noexcept = default;
  template<class T> constexpr variant(const T& t) noexcept : index{id<T>} { }

  template<class T> constexpr auto reset(const T&) noexcept requires (type_traits::is_same_v<T, Ts> or ...) {
    index = id<T>;
    return true;
  }

  template<class... TArgs> requires ([]<class T> { return (type_traits::is_same_v<T, TArgs> or ...); }.template operator()<Ts>() or ...)
  constexpr auto reset(const variant<TArgs...>& other) noexcept {
    if (other.index != -1) {
      index = other.index;
      return true;
    }
    return false;
  }

  char index{-1};
};

inline constexpr auto if_else = []<class Fn, template<class...> class T, class... Ts>(Fn&& fn, const T<Ts...>& v) {
  return [&]<size_t... Ns>(utility::index_sequence<Ns...>) {
    return ([&] {
      if (v.index == Ns) return fn(Ts{});
      return false;
    }() or ...);
  }(utility::make_index_sequence<sizeof...(Ts)>{});
};
inline constexpr auto jmp_table = []<class Fn, template<class...> class T, class... Ts>(Fn&& fn, const T<Ts...>& v) {
  static constexpr bool (*dispatch[])(Fn){[](Fn) { return false; }, [](Fn fn) { return fn(Ts{}); }...};
  return dispatch[v.index](fn);
};
template<class... Ts> struct overload : Ts... {
  using value_type = mp::type_list<Ts...>;
  using Ts::operator()...;
};
template<class... Ts> overload(Ts...) -> overload<Ts...>;

template<class T>
  requires (requires (T t) { t(); })
class sm {
  template<class TState>
  static constexpr auto add_state(auto& states, mp::type_list<TState>) {
    const auto new_state = mp::meta<TState>;
    if (new_state == mp::meta<void> or new_state == mp::meta<type_traits::none>) return;
    for (const auto& state : states) if (state == new_state) return;
    states.push_back(new_state);
  }
  template<template<class...> class TList, class... Ts>
  static constexpr auto add_state(auto& states, mp::type_list<TList<Ts...>>) {
    (add_state(states, mp::type_list<Ts>{}), ...);
  }
  static constexpr auto states = []<class... Ts>(mp::type_list<Ts...>) {
    static_vector<mp::info, 2u * sizeof...(Ts)> states{};
    (add_state(states, mp::type_list<typename type_traits::transition_traits<Ts>::src>{}), ...);
    (add_state(states, mp::type_list<typename type_traits::transition_traits<Ts>::dst>{}), ...);
    return states;
  }(typename type_traits::remove_cvref_t<decltype(utility::declval<T>()())>::value_type{});

  template<class TEvent>
  static constexpr auto dispatchable =
    []<class... TStates>(mp::type_list<TStates...>) {
      return (requires(T t, TStates state, TEvent event) { t()(state, event); } or ...);
    }(mp::apply_t<mp::type_list, states>{});

 public:
  constexpr sm(const auto& t) : t_{t} { }

  template<class TEvent, auto dispatch = if_else> requires dispatchable<TEvent>
  constexpr auto process_event(const TEvent& event) -> bool {
    return dispatch([&](const auto& state) {
      if constexpr (requires { states_.reset(t_()(state, event)); }) {
        return states_.reset(t_()(state, event));
      } else if constexpr (requires { t_()(state, event); }) {
        t_()(state, event);
        return true;
      } else {
        return false;
      }
    }, states_);
  }

  template<auto dispatch = if_else> constexpr auto visit(auto&& fn) const {
    return dispatch(fn, states_);
  };

 private:
  [[no_unique_address]] T t_{};
  [[no_unique_address]] mp::apply_t<variant, states> states_ = mp::type_of<states[0u]>{};
};
template<class T> requires requires (T t) { t(); } sm(T) -> sm<T>;
template<class T> sm(T) -> sm<utility::wrapper<T>>;
struct X {}; // terminate state
} // namespace sml

#ifndef NTEST
static_assert(([] {
  constexpr auto expect = [](bool cond) { if (not cond) { void failed(); failed(); } };
  constexpr auto is = []<class... TStates>(const auto& sm, sml::mp::type_list<TStates...>) {
    return sm.visit([&]<class TState>(const TState&) {
      return (sml::type_traits::is_same_v<TStates, TState> and ...);
    });
  };

  // states
  struct idle {};
  struct s1 {};
  struct s2 {};
  struct s3 {};
  struct s4 {};

  // events
  struct e1 {};
  struct e2 {};
  struct e3 {};
  struct e { int value{}; };
  struct unexpected {};

  // sml::sm::process_event
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; }
    };

    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2>{}));
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

    expect(is(sm, sml::mp::type_list<idle>{}));
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
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(sm.process_event(e2{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 1);
    expect(is(sm, sml::mp::type_list<s3>{}));
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
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(sm.process_event(e2{}));
    expect(on_entry_calls == 1);
    expect(on_exit_calls == 0);
    expect(is(sm, sml::mp::type_list<s2>{}));
  }
#endif

  // process_event[same event multiple times]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
      [](s2, e1) -> s3 { return {}; },
    };

    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s3>{}));
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
    expect(is(sm, sml::mp::type_list<s2>{}));

    expect(sm.process_event(e{{}}));
    expect(is(sm, sml::mp::type_list<s1>{}));
    expect(not sm.process_event(e2{}));  // ignored
    expect(is(sm, sml::mp::type_list<s1>{}));

    expect(sm.process_event(e1{}));  // s1 -> s2
    expect(is(sm, sml::mp::type_list<s2>{}));

    expect(sm.process_event(e2{}));  // s2 -> s3
    expect(is(sm, sml::mp::type_list<s3>{}));

    expect(sm.process_event(e{}));  // _ -> s1
    expect(is(sm, sml::mp::type_list<s1>{}));
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
      expect(is(sm, sml::mp::type_list<s1>{}));
      expect(sm.process_event(e1{}));
      expect(is(sm, sml::mp::type_list<s2>{}));
    }

    {
      sml::sm sm{test};
      expect(is(sm, sml::mp::type_list<s1>{}));
      expect(sm.process_event(e2{}));
      expect(is(sm, sml::mp::type_list<s2>{}));
    }
  }

  // events[same event transitions]
  {
    sml::sm sm = sml::overload{
      [](idle, e1) -> s1 { return {}; },
      [](s1, e1) -> s2 { return {}; },
      [](s2, e1) -> idle { return {}; },
    };

    expect(is(sm, sml::mp::type_list<idle>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s1>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<idle>{}));
  }

  // transition_table[multiple transitions]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> s2 { return {}; },
      [](s2, e2) -> s1 { return {}; },
    };

    expect(is(sm, sml::mp::type_list<s1>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(not sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2>{}));
    expect(sm.process_event(e2{}));
    expect(is(sm, sml::mp::type_list<s1>{}));
  }

  // transition_table[terminated state]
  {
    sml::sm sm = sml::overload{
      [](s1, e1) -> sml::X { return {}; },
    };

    expect(is(sm, sml::mp::type_list<s1>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<sml::X>{}));
    expect(not sm.process_event(e1{}));
  }

  // transition_table[guards/actions]
  {
    unsigned calls{};

    sml::sm sm = sml::overload{
      [&](s1, const e& event) -> sml::variant<s1, s2> {
        if (event.value) {
          ++calls;
          return s2{};
        }
        return {};
      },
    };

    expect(not sm.process_event(e{false}));
    expect(is(sm, sml::mp::type_list<s1>{}));
    expect(sm.process_event(e{true}));
    expect(is(sm, sml::mp::type_list<s2>{}));
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
    expect(is(sm, sml::mp::type_list<s3>{}));
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

    expect(is(sm, sml::mp::type_list<s1, s3>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2, s3>{}));
    expect(sm.process_event(e2{}));
    expect(is(sm, sml::mp::type_list<s2, s4>{}));
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

    expect(is(sm, sml::mp::type_list<s1, s3>{}));
    expect(sm.process_event(e1{}));
    expect(is(sm, sml::mp::type_list<s2, s3>{}));
    expect(sm.process_event(e2{}));
    expect(is(sm, sml::mp::type_list<X, s3>{}));
    expect(sm.process_event(e3{}));
    expect(is(sm, sml::mp::type_list<X, X>{}));
  }
#endif

  // dependencies
  {
    struct s {
      bool& in;
      int& out;
      constexpr auto guard() { return in; };
      constexpr auto operator()() {
        return sml::overload{
          [this](s1, const e& event) { if (guard()) out = event.value; },
        };
      }
    };

    {
      bool in{false};
      int out{};
      s _{in, out};
      sml::sm sm{_};
      expect(sm.process_event(e{.value = 42}));
      expect(0 == out);
    }

    {
      bool in{true};
      int out{};
      s _{in, out};
      sml::sm sm{_};
      expect(sm.process_event(e{.value = 42}));
      expect(42 == out);
    }
  }

  // example.connection
  {
    struct connect {};
    struct established {};
    struct ping { bool valid{}; };
    struct disconnect {};
    struct timeout {};

    {
      struct sm {
        struct Disconnected {};
        struct Connecting {};
        struct Connected {};

        constexpr void establish(){}
        constexpr void close(){}
        constexpr void reset_timeout(){ }

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
      expect(is(connection, sml::mp::type_list<sm::Disconnected>{}));
      expect(connection.process_event(connect{}));
      expect(is(connection, sml::mp::type_list<sm::Connecting>{}));
      expect(connection.process_event(established{}));
      expect(is(connection, sml::mp::type_list<sm::Connected>{}));
      expect(connection.process_event(ping{.valid = true}));
      expect(is(connection, sml::mp::type_list<sm::Connected>{}));
      expect(connection.process_event(disconnect{}));
      expect(is(connection, sml::mp::type_list<sm::Disconnected>{}));
    }

    #if __cpp_constexpr >= 202211L
    {
      struct sm {
        struct Disconnected {};
        struct Connecting {};
        struct Connected {};

        static constexpr void establish(){}
        static constexpr void close(){}
        static constexpr void reset_timeout(){ }

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
      expect(is(connection, sml::mp::type_list<sm::Disconnected>{}));
      expect(connection.process_event(connect{}));
      expect(is(connection, sml::mp::type_list<sm::Connecting>{}));
      expect(connection.process_event(established{}));
      expect(is(connection, sml::mp::type_list<sm::Connected>{}));
      expect(connection.process_event(ping{.valid = true}));
      expect(is(connection, sml::mp::type_list<sm::Connected>{}));
      expect(connection.process_event(disconnect{}));
      expect(is(connection, sml::mp::type_list<sm::Disconnected>{}));
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
      expect(is(connection, sml::mp::type_list<Disconnected>{}));
      expect(connection.process_event(connect{}));
      expect(is(connection, sml::mp::type_list<Connecting>{}));
      expect(connection.process_event(established{}));
      expect(is(connection, sml::mp::type_list<Connected>{}));
      expect(connection.process_event(ping{.valid = true}));
      expect(is(connection, sml::mp::type_list<Connected>{}));
      expect(connection.process_event(disconnect{}));
      expect(is(connection, sml::mp::type_list<Disconnected>{}));
    }
    #endif
  }
}(), true));
#endif // NTEST
