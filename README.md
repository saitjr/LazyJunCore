# LazyJunCore

LazyJunCore is an image tool box in Swift that lets users combine each tool to a weapon. Actually, these tools are build for LazyJun app (not finish yet).

## Features

- [x] rename (rename image)


- [x] even (guarantee that image size is even number)

-   [] compress (optimize image)

- [x] generate2x (generate 2x image)


- [x] generateSize (generate sizes which are given)

## Usage

You can combine the handler which you want to act on image.

### One-to-One

one image to one image

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
3.  guarantee the image size
4.  append image name "@2x"
5.  run

### One-to-Many

one image generate a lots of image.

```swift
let iconSizes: [CGSize] = [CGSize(width: 10, height: 10),
                           CGSize(width: 20, height: 20)]

generateSize(iconSizes)
    ==> run(fromPath)
```

## License

Under MIT License.