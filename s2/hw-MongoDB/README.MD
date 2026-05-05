### создание коллекции

```
db.createCollection("books")
```

### создание документа

```
db.books.insertOne({
  title: "Чистый код",
  genre: "programming",
  price: 3200,
  available: true,
  tags: ["программирование", "best practices"],
  author: {
    name: "Robert Martin",
    country: "USA"
  }
})
```

### вывести все книги, которые есть в наличии:

```
db.books.find({ available: true }).pretty()

[
  {
    _id: ObjectId('69eb8532452a5e6b4444ba89'),
    title: 'Чистый код',
    genre: 'programming',
    price: 3200,
    available: true,
    tags: [ 'программирование', 'best practices' ],
    author: { name: 'Robert Martin', country: 'USA' }
  }
]
```

### добавление нескольких документов

```
db.books.insertMany([
  {
    title: "MongoDB Basics",
    genre: "database",
    price: 2800,
    available: true,
    tags: ["mongodb", "nosql"],
    author: {
      name: "John Smith",
      country: "Canada"
    }
  },
  {
    title: "JavaScript для начинающих",
    genre: "programming",
    price: 1900,
    available: true,
    tags: ["javascript", "frontend"],
    author: {
      name: "Иван Петров",
      country: "Russia"
    }
  },
  {
    title: "История Японии",
    genre: "history",
    price: 1500,
    available: false,
    tags: ["история", "азия"],
    author: {
      name: "Ken Watanabe",
      country: "Japan"
    }
  },
  {
    title: "Алгоритмы и структуры данных",
    genre: "programming",
    price: 4100,
    available: true,
    tags: ["алгоритмы", "структуры данных"],
    author: {
      name: "Thomas Cormen",
      country: "USA"
    }
  }
])
```

### сложный запрос

```
db.books.find(
  {
    genre: "programming",
    price: { $gt: 2000 },
    available: true
  },
  {
    _id: 0,
    title: 1,
    price: 1
  }
).pretty()

 { title: 'Чистый код', price: 3200 },
 { title: 'Алгоритмы и структуры данных', price: 4100 }
```