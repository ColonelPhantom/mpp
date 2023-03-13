# MPP - MetaProgrammer's Preprocessor
MPP is a Lua-based preprocessor that enables metaprogramming in any language.

## Features
MPP's most important features are

- Keeping files intact: MPP uses special directives and so it should work on any already existing program! By default, all lines that start with `@` are seen as MPP code. This can be reconfigured for languages that already use `@`, like Python or Java. `$foo$` is also special syntax, which will become configurable in the near future.
- Full Lua interpreter - you can use all Lua features in the metaprogram.

## Possibilities
MPP aims to be very flexible. That said, there are some common patterns you may wish to implement:

### Templates
You can emulate templates in MPP by defining a Lua function. For example, a `sum` function in C can be written as follows:
```c
@function sum_t(type, base)
    @local base = base or 0
    $type$ sum_$type$($type$ *xs, size_t len) {
        $type$ sum = $base$;
        for(size_t i = 0; i < len; i++) {
            sum += xs[i];
        }
        return sum;
    }
@end
```
This will generate a function `int sum_int(int *xs, size_t len)`.

### Hooks
When metaprogramming, hooks are a way to make functionality extensible. This enables a form of plugin-based programming, where you write plugins that hook into existing code. For example:
```c
// Set up hook set
@hooks = mpp.hooks()
int evaluate(char op, int a, int b) {
    switch(char) {
        // Enable hooking here
        @hooks("eval")
    }
    return 0;
}
// Inject addition and multiplication into hook
@hooks.eval("case '+': return a+b;")
@hooks.eval("case '*': return a*b;")
```
By putting the hook calls into separate modules and functions, it is possible to increase the locality of behaviour. Imagine a real programming language, which needs operators to be added in multiple places (such as the parser and the interpreter).

## Supported programming languages
MPP aims to be language-agnostic but has some features that are language-specific, mostly for convenience.

### C
For C, we currently support declaring structs. This can be done with the Lua function `mpp.c.struct(name, [values])`. You can then extend the struct by setting fields to their declaration. For example a linked list can be defined as
```lua
@local l = mpp.c.struct("linkedlist")
@-- the struct is accessible via both the return value as well as the "linkedlist" global:
@l.value = "int value"
@linkedlist.next = "struct linkedlist *next"
```
The struct can now be extended in a similar way as via hooks, simply by setting new keys. In addition, conflicting member names cause errors.
Finally, it should also be possible to perform reflection with this. However, currently this is rather problematic as it is possible the declarations may be extended at a later point in the runtime of the metaprogram. Unfortunately, using Lua may make it very hard to solve this problem, as it does not really support laziness which already needs to be emulated to support things like hooks.
