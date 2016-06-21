# LazyJunCore

macOS command line tool of image handler. Write for LazyJun app (not finish yet).

## Usage

You can combine the handler which you want to act on image.

eg.

```swift
rename(.SubSuffix, string: "@3x")
    >|< generate2x()
    >|< even()
    >|< rename(.AppendSuffix, string: "@2x")
    => run(fromPath)
```

This chain  means :

1.  sub image name "@3x"
2.  generate 2x image
3.  guarantee the image pixels are even number
4.  append image name "@2x"
5.  run

## License

Under MIT License.