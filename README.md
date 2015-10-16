### SwiftRuby

RubyNative is a port of the Ruby core api to Swift intended to be used with [Diamond](https://github.com/RubyNative/Diamond)
scripts or any Swift Program that would like simpler access to file i/o than is offered
by Foundation kit. It also extends Swift's String and Array classes and will provide a
well integrated Regexp class to take the burden off the programmer dealing with 
uncompromising Swift Strings.

Why port Ruby to Swift? Using a strictly typed and scoped language for scripting
avoids may of the pitfalls of a dynamic language and allows for auto-completion
when working in the editor. This makes your scripts run faster in terms of
developer time and very much so at run time.

Seems like a lot of low level UNIX code to me? We chose to stay close to the metal
as the Ruby apis seem based on the POSIX interface. It is also not clear Foundation will
be available when Swift is released for Linux. At the moment the project has minimal
dependencies on Foundation classes NSURL and NSRegularExpression for things that it
would not be worth replicating until the smoke clears for Swift on Linux.

Very much a work in progress if you see a class or method that is not implemented
that you feel would be useful make a pull request to add it to the file MISSING.md
an we'll have a look at it or better still, join the team and make your own RubyNative 
framework others can include using CocoaPods or the inbuilt clone mechanism in CocoaScript.

More later...
