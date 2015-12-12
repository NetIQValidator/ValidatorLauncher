//: Playground - noun: a place where people can play

import Cocoa

var songs = [String]()
songs = ["Shake it Off", "You Belong with Me", "Love Story"]
var songs2 = ["Today was a Fairytale", "White Horse", "Fifteen"]
var both = songs + songs2
both += ["test"]

var people = ["players", "haters", "heart-breakers", "fakers"]
var actions = ["play", "hate", "break", "fake"]

for i in 0 ... 3 {
    print("\(people[i]) gonna \(actions[i])")
}

func albumReleasedYear(year: Int) -> String? {
    switch year {
    case 2006: return "Taylor Swift"
    case 2008: return "Fearless"
    case 2010: return "Speak Now"
    case 2012: return "Red"
    case 2014: return "1989"
    default: return nil
    }
}

let album = albumReleasedYear(2006) ?? "unknown"

print("The album is \(album)")

struct Person {
    var clothes: String {
        willSet {
            updateUI("I'm changing from \(clothes) to \(newValue)")
        }

        didSet {
            updateUI("I just changed from \(oldValue) to \(clothes)")
        }
    }
}

func updateUI(msg: String) {
    print(msg)
}

var taylor = Person(clothes: "T-shirts")
taylor.clothes = "short skirts"
