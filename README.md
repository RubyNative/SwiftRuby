### RubyNative

RubyNative is a port of the Ruby core api to Swift intended to be used with CocoaScript
scripts or any Swift Program that would like simpler access to file i/o than is offered
by Foundation kit. It also extends Swift's String and Array classes and provides a
well integrated Regexp class to take the burden off the busy programmer.

Why port Ruby to Swift? Using a strictly types and scoped language for scripting
avoids may of the pitfall of a dynamic language and allows for auto-completion
when working in the editor. This makes your scripts run faster both in terms of
developer time very much so and at run time.

Seems like a lot of low level UNIX code to me? We chose to stay close to the metal
as the ruby apis seem based on a POSIX interface. It is also not clear Foundation will
be available when Swift is released for Linux. At the moment the project has minimal
dependencies on Foundation classes NSURL and NSRegularExpression for things that it
would not be worth replicating until it is clear the smoke clears for Swift on Linux.

Very much a work in progress if you see a class or method that is not implemented
you feel would be useful make a pull request to add it to the file MISSING.md
an we'll have a look at it or better join the team and make your own RubyNative 
framework can include using CocoaPods or the inbuilt clone mechanism in CocoaScript.

More later...
