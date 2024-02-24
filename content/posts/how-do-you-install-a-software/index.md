---
title: "How Do You Install a Software?"
date: 2023-07-19T11:56:29+09:00
categories: ["Software Engineering"]
draft: true
---

Let me ask you a question.
How do you install a software?

I think installing a software the right way is the missing part of undergraduate CS courses.
I know, there is the [missing semester offered by MIT](https://missing.csail.mit.edu/), but it's not enough in my opinion.
It teaches you how to work on shell environment and other things (so you look like a real hacker),
but one might not be able to figure out how to put a software onto his/her system the right way right after
finishing the course.

Installing a software is a fundamental skill to be an software engineer.
At the end of the day, you will get stuck being questioning why your `apt install blah-blah` does not work.
Or, you might be able to enjoy a coffee time at work, waiting for `npm install` to finish. (Not a good one, though!)

{{<bundle-image name="my-code-is-compiling.png" alt="My code is compiling!" caption="npm install time is a coffee time" width="50%">}}


## Package Manager

The simplest(really?) and easiest(it seems) way to install a software is to use a package manager.

- If you are on Linux, you probably use the package manager such as `apt-get` or `yum`.
- If you are on Windows, you probably use the Windows installer.
- If you are on Mac, you probably use `brew`.

Let's take an example of installing `hugo`, the static site generator, which is running this blog.
And I will assume you are on Ubuntu Linux (WSL2, to be specific).

If you decided to use the package manager `apt-get`,
you can install `hugo` by running the following command.

```bash
$ sudo apt-get install hugo
```

Let's break this command down.

1. `$`: You are not the super user (you don't need to type this on your shell!)
1. `sudo`: You need the super user previlege to run this command (WHY?)
1. `apt-get install`: You are telling the package manager to install a software.
1. `hugo`: The name of the package you want to install.


# Downloading a Binary

But that's not the end of the story.
You can also install a software downloading the compiled binary, or
build the software from the source code.



