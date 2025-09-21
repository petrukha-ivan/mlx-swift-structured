# MLX Structured

[MLX](https://github.com/ml-explore/mlx-swift) Structured is a Swift library for structured output generation using constrained decoding. It's built on top of the [XGrammar](https://github.com/mlc-ai/xgrammar) library, which provides efficient, flexible, and portable structured generation. You can learn more about the XGrammar algorithm in their [technical report](https://arxiv.org/abs/2411.15100).

## Installation

To use MLX Structured in your project, add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/petrukha-ivan/mlx-swift-structured", from: "0.0.1")
]
```

Don't forget to add the library as a dependency for your targets:

```swift
dependencies: [
    .product(name: "MLXStructured", package: "mlx-swift-structured")
]               
```

## Usage

### Grammar

Start by defining a `Grammar`. You can use JSON Schema to describe the desired output:

```swift
let grammar = try Grammar.schema(.object(
    description: "Person info",
    properties: [
        "name": .string(),
        "age": .integer()
    ], required: [
        "name",
        "age"
    ]
))
```

Starting with macOS 26 and iOS 26, you can use a `@Generable` type as a grammar source:

```swift
@Generable
struct PersonInfo {
    
    @Guide(description: "Person name")
    let name: String
    
    @Guide(description: "Person age")
    let age: Int
}

let grammar = try Grammar.schema(generable: PersonInfo.self)
```

You can also use regex:

```swift
let grammar = Grammar.regex(#"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#) // Simple email regex
```

Or define your own grammar rules with [EBNF](https://en.wikipedia.org/wiki/Extended_Backus–Naur_form) syntax:

```swift
let grammar = Grammar.ebnf(#"root ::= ("YES" | "NO")"#) // Answer only "YES" or "NO"
```

### Generation

To use a defined grammar during text generation, create a logit processor and pass it to `TokenIterator`:

```swift
let processor = try await GrammarMaskedLogitProcessor.from(configuration: context.configuration, grammar: grammar)
let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler, maxTokens: 256)
```

You can find more usage examples in the `MLXStructuredCLI` target and in the unit tests.

## Experiments

### Performance

In synthetic tests with the Llama model and a vocabulary of 60,000 tokens, the performance drop was less than 10%. However, with real models the results are worse. In practice, you can expect generation speed to be about 15% slower.
The exact slowdown depends on the model, vocabulary size, and the complexity of your grammar.

| Model | Vocab Size | Plain (tokens/s) | Constrained (tokens/s) |
| - | - | - | - |
| Qwen3 4B | 151,936 | 102 | 87 |
| Llama3.2 3B | 128,256 | 131 | 109 |
| Gemma3 270M | 262,144 | 186 | 160 |

These results show that while constrained decoding adds some overhead, it still remains fast enough for practical use.

### Accuracy

For example, given a task to extract components from text and output them in JSON format, the prompt is:

```plain
Instruction: Extract movie record from the text, output in JSON format according to schema: \(grammar.raw)
Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine.
```

And the grammar definition looks like this:

```swift
let grammar = try Grammar.schema(.object(
    description: "Movie record",
    properties: [
        "title": .string(),
        "year": .integer(),
        "genres": .array(items: .string(), maxItems: 3),
        "director": .string(),
        "actors": .array(items: .string(), maxItems: 10)
    ], required: [
        "title",
        "year",
        "genres",
        "director",
        "actors"
    ]
))
```

For large proprietary models like ChatGPT, this is not a problem. With the right prompt, they can successfully generate valid JSON even without constrained decoding. But with smaller models like Gemma3 270M (especially when quantized to 4-bit) the output almost always contains invalid JSON, even if the schema is provided in the prompt.

```plain
[
  "title": "The Dark Knight",
  "actors": [
    "Christian Bale",
    "Heath Ledger",
    "Michael Caine"
  ],
  "genre": "crime",
  "director": "Christopher Nolan",
  "actors": [
    "Christian Bale",
    "Heath Ledger",
    "Michael Caine"
  ],
  "description": "The Dark Knight is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, Michael Caine."
]
```

This output has several issues:

- Root starts with `[` instead of `{`
- Incorrect key and type for `genres` field
- Missing required `year` field
- Duplicated `actors` field
- Extra `description` field

Here is the output using constrained decoding:

```plain
{
  "director": "Christian Bale",
  "year": 2008,
  "title": "The Dark Knight",
  "actors": [
    "Christian Bale",
    "Heath Ledger",
    "Michael Caine"
  ],
  "genres": [
    "crime",
    "action",
    "mystery"
  ]
}
```

The order of keys here is random because `Dictionary` in Swift is unordered. I plan to address this in the future. However, the output is fully valid JSON that exactly matches the provided schema. This shows that, with the right approach, even small models like Gemma3 270M 4-bit (which is just 150 MB) can produce correct structured output.

## Troubleshooting

This library is still in an early stage of development. While it is already functional, it may have unexpected issues or even crash your program. If you encounter a problem, please create an issue or open a pull request. Contributions are welcome!
