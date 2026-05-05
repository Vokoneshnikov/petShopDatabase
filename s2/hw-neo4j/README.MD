### вход

```
docker exec -it neo4j-demo cypher-shell -u neo4j -p password
```

### импортировала данные, втавила категорию

```
CREATE (:Category {
  categoryID: 'databases',
  title: 'Databases'
});
```

### добавление статьи

```
CREATE (:Article {
  articleID: 'Neo4j for beginners',
  title: 'Neo4j for beginners'
});
```

### связь статьи с категорией

```
MATCH (a:Article {articleID: 'Neo4j for beginners'})
MATCH (c:Category {categoryID: 'databases'})
CREATE (a)-[:IS_IN]->(c);
```

### добавление читателя

```
CREATE (:Reader {
  readerID: 'vera',
  nickname: 'Vera',
  email: 'vera@example.com'
});
```

### добавление читателя

```
CREATE (:Reader {
  readerID: 'vera',
  nickname: 'Vera',
  email: 'vera@example.com'
});
```

### связь с 3мя стаьями

```
MATCH (r:Reader {readerID: 'vera'})
MATCH (a:Article)
WITH r, a LIMIT 3
CREATE (r)-[:READ]->(a);
```

### добавление читателя

```
CREATE (:Reader {
  readerID: 'vera',
  nickname: 'Vera',
  email: 'vera@example.com'
});
```

### отобразить всех пользователей, статьи и связи между ними

```
MATCH (r:Reader)-[rel:READ]->(a:Article)
RETURN r, rel, a;

+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| r                                                                                                       | rel     | a                                                                                            |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| (:Reader {nickname: "Vera", readerID: "vera", email: "vera@example.com"})                               | [:READ] | (:Article {articleID: "River - library for incremental machine learning on streaming data"}) |
| (:Reader {nickname: "IvanIva", readerID: "Ivan Ivanov", email: "IvanIvanov@email.com"})                 | [:READ] | (:Article {articleID: "River - library for incremental machine learning on streaming data"}) |
| (:Reader {nickname: "Vera", readerID: "vera", email: "vera@example.com"})                               | [:READ] | (:Article {articleID: "QlikView data transformation and model construction"})                |
| (:Reader {nickname: "Petrov", readerID: "Petr Petrov", email: "PetrPetrov@email.com"})                  | [:READ] | (:Article {articleID: "QlikView data transformation and model construction"})                |
| (:Reader {nickname: "Vera", readerID: "vera", email: "vera@example.com"})                               | [:READ] | (:Article {articleID: "Creating new features to improve the quality of machine learning"})   |
| (:Reader {nickname: "Ilya12131", readerID: "Ilya Shevchenko", email: "IlyaShevchenko@email.com"})       | [:READ] | (:Article {articleID: "Creating new features to improve the quality of machine learning"})   |
| (:Reader {nickname: "Ilya12131", readerID: "Ilya Shevchenko", email: "IlyaShevchenko@email.com"})       | [:READ] | (:Article {articleID: "AI learns your mood or Perception for Autonomous Systems in action"}) |
| (:Reader {nickname: "Aleksei1989", readerID: "Aleksei Stepankov", email: "AlekseiStepankov@email.com"}) | [:READ] | (:Article {articleID: "AI learns your mood or Perception for Autonomous Systems in action"}) |
| (:Reader {nickname: "Aleksei1989", readerID: "Aleksei Stepankov", email: "AlekseiStepankov@email.com"}) | [:READ] | (:Article {articleID: "Gradient boosting with CatBoost (part 2/3)"})                         |
| (:Reader {nickname: "AnnaCool", readerID: "Anna Sherp", email: "AnnaSherp@email.com"})                  | [:READ] | (:Article {articleID: "Gradient boosting with CatBoost (part 2/3)"})                         |
| (:Reader {nickname: "AnnaCool", readerID: "Anna Sherp", email: "AnnaSherp@email.com"})                  | [:READ] | (:Article {articleID: "Text analysis by means of the Stanza library"})                       |
| (:Reader {nickname: "Aleksss", readerID: "Aleksandra Osokina", email: "AleksandraOsokina@email.com"})   | [:READ] | (:Article {articleID: "Text analysis by means of the Stanza library"})                       |
| (:Reader {nickname: "Aleksss", readerID: "Aleksandra Osokina", email: "AleksandraOsokina@email.com"})   | [:READ] | (:Article {articleID: "Clustering of clients. Analysis of the client's personality"})        |
| (:Reader {nickname: "IvanIva", readerID: "Ivan Ivanov", email: "IvanIvanov@email.com"})                 | [:READ] | (:Article {articleID: "Clustering of clients. Analysis of the client's personality"})        |
| (:Reader {nickname: "Petrov", readerID: "Petr Petrov", email: "PetrPetrov@email.com"})                  | [:READ] | (:Article {articleID: "Data visualization using the Dash web framework"})                    |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

### Выбрать пользователя и найти категории, которые он читает

```
MATCH (r:Reader {readerID: 'vera'})-[:READ]->(a:Article)-[:IS_IN]->(c:Category)
RETURN DISTINCT r.nickname AS reader, c.title AS category;

+-----------------------------+
| reader | category           |
+-----------------------------+
| "Vera" | "Machine learning" |
| "Vera" | "Data analysis"    |
+-----------------------------+
```

### Найти самых активных читателей

```
MATCH (r:Reader)-[:READ]->(a:Article)
RETURN r.readerID AS reader, count(a) AS articles_read
ORDER BY articles_read DESC;

+--------------------------------------+
| reader               | articles_read |
+--------------------------------------+
| "vera"               | 3             |
| "Ivan Ivanov"        | 2             |
| "Petr Petrov"        | 2             |
| "Ilya Shevchenko"    | 2             |
| "Aleksei Stepankov"  | 2             |
| "Anna Sherp"         | 2             |
| "Aleksandra Osokina" | 2             |
+--------------------------------------+
```

## Выбрать статью и найти похожие статьи

### похожие статьи — это статьи, которые читают те же пользователи.

```
MATCH (target:Article {articleID: 'Neo4j for beginners'})<-[:READ]-(r:Reader)-[:READ]->(similar:Article)
WHERE similar <> target
RETURN similar.articleID AS similar_article, count(r) AS common_readers
ORDER BY common_readers DESC;

+----------------------------------+
| similar_article | common_readers |
+----------------------------------+
+----------------------------------+
```

## рекомендации по категориям

### найти категории, которые читает пользователь, и предложить статьи из этих категорий, которые он ещё не читал:

```
MATCH (r:Reader {readerID: 'vera'})-[:READ]->(:Article)-[:IS_IN]->(c:Category)
MATCH (recommended:Article)-[:IS_IN]->(c)
WHERE NOT (r)-[:READ]->(recommended)
RETURN DISTINCT recommended.articleID AS recommended_article, c.title AS category
LIMIT 10;

+----------------------------------------------------------------------------------------+
| recommended_article                                                  | category        |
+----------------------------------------------------------------------------------------+
| "Clustering of clients. Analysis of the client's personality"        | "Data analysis" |
| "AI learns your mood or Perception for Autonomous Systems in action" | "Data analysis" |
+----------------------------------------------------------------------------------------+
```