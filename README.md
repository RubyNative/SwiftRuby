### SwiftRuby

RubyNative is a port of the Ruby core api to Swift intended to be used with [Diamond](https://github.com/RubyNative/Diamond)
script interpreter or any Swift Program that would like simpler access to file i/o than is offered
by Foundation kit. It also extends Swift's String and Array classes and will provide a
well integrated Regexp class to take the burden off the programmer dealing with 
uncompromising Swift Strings.

Why port Ruby to Swift? Using a strictly typed and scoped language for scripting
avoids may of the pitfalls of a dynamic language and allows for auto-completion
when working in the editor. This makes your scripts run faster in terms of
developer time and very much so at run time. The languages are also a good
fit syntactically.

Seems like a lot of low level UNIX code? We chose to stay close to the metal and the
Ruby apis seem based on the POSIX interface. It is also not clear Foundation will
be available when Swift is released for Linux. For now the project has minimal
dependencies on Foundation classes NSURL and NSRegularExpression for things that it
would not be worth replicating until the smoke clears for Swift on Linux.

At this stage, Ruby's [Dir](http://ruby-doc.org/core-2.2.3/Dir.html), [IO](http://ruby-doc.org/core-2.2.3/IO.html),
[File](http://ruby-doc.org/core-2.2.3/File.html), [StringIO](http://ruby-doc.org/stdlib-2.2.3/libdoc/stringio/rdoc/StringIO.html),
[Time](http://ruby-doc.org/core-2.2.3/Time.html) and [Stat](http://ruby-doc.org/core-2.2.3/File/Stat.html) classes have been implemented.
These classes follow the original documented functionality as closely as possible.
Input arguments are generally protocols such as `string_like` or `data_like`
to allow for automatic conversion between types. Return values are concrete
types String Int, Float or Data or an instance.

A flavour of the common Ruby idioms implemented in Swift thus far is given below:

![Icon](http://injectionforxcode.johnholdsworth.com/ruby.png)

SwiftRuby has avoided using operator overloading as much as Ruby with one exception:
subscripting when working with Strings. There are two general forms. Subscripting
with integers to extract ranges from Strings and subscripting with Strings to
provide a succinct syntax for Regular Expressions.

### Subscripting Strings

At danger of unpicking the sterling work Swift has done to protect us all from
String internals simple extensions have been defined to make scripting easier:

![Icon](http://injectionforxcode.johnholdsworth.com/strings.png)

### Subscripting Strings with a String as syntax for Regexp

If you think about it, the logical index into a string is a Regexp. Ruby toys with this idea
but SwiftRuby takes this much further. This is best explained by the following examples:

![Icon](http://injectionforxcode.johnholdsworth.com/regexps.png)

### License is MIT

SwiftRuby is available under an MIT License. If you have any comments or suggestions, the
authors can be contacted on Twitter [@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode).
