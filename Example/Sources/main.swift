import Kuzu

let db = try! Database()
let conn = try! Connection(db)

// Create schema and load data
let queries = [
    "CREATE NODE TABLE User(name STRING PRIMARY KEY, age INT64)",
    "CREATE NODE TABLE City(name STRING PRIMARY KEY, population INT64)",
    "CREATE REL TABLE Follows(FROM User TO User, since INT64)",
    "CREATE REL TABLE LivesIn(FROM User TO City)",
    "COPY User FROM 'data/user.csv'",
    "COPY City FROM 'data/city.csv'",
    "COPY Follows FROM 'data/follows.csv'",
    "COPY LivesIn FROM 'data/lives-in.csv'",
]

for query in queries {
    _ = try! conn.query(query)
}

// Execute Cypher query
let res = try! conn.query("MATCH (a:User)-[e:Follows]->(b:User) RETURN a.name, e.since, b.name")
for tuple in res {
    let dict = try! tuple.getAsDictionary()
    print(dict)
}
