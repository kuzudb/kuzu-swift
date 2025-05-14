import Testing
@testable import Kuzu

@Test func example() async throws {
    let systemConfig = Kuzu.SystemConfig()
    let db = try Kuzu.Database("")
    let conn = try Kuzu.Connection(db)
    var result = conn.query("CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
    print(result)
    result = conn.query("CREATE NODE TABLE City(name STRING, population INT64, PRIMARY KEY (name))")
    print(result)
    result = conn.query("CREATE REL TABLE Follows(FROM User TO User, since INT64)")
    print(result)
    result = conn.query("CREATE REL TABLE LivesIn(FROM User TO City)")
    print(result)
    result = conn.query("COPY User From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/user.csv'")
    print(result)
    result = conn.query("COPY City From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/city.csv'")
    print(result)
    result = conn.query("COPY Follows From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/follows.csv'")
    print(result)
    result = conn.query("COPY LivesIn From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/lives-in.csv'")
    print(result)
    result = conn.query("MATCH (u:User)-[l:LivesIn]->(c:City) RETURN u.name, c.name")
    print(result)
    
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}
