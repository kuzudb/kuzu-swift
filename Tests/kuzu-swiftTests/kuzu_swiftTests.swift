import Foundation
import Testing

@testable import Kuzu

@Test func example() async throws {
    let systemConfig = Kuzu.SystemConfig()
    let db = try Kuzu.Database("")
    let conn = try Kuzu.Connection(db)
    var result = try conn.query(
        "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))"
    )
    print(result)
    result = try conn.query(
        "CREATE NODE TABLE City(name STRING, population INT64, PRIMARY KEY (name))"
    )
    print(result)
    result = try conn.query(
        "CREATE REL TABLE Follows(FROM User TO User, since INT64)"
    )
    print(result)
    result = try conn.query("CREATE REL TABLE LivesIn(FROM User TO City)")
    print(result)
    result = try conn.query(
        "COPY User From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/user.csv'"
    )
    print(result)
    result = try conn.query(
        "COPY City From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/city.csv'"
    )
    print(result)
    result = try conn.query(
        "COPY Follows From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/follows.csv'"
    )
    print(result)
    result = try conn.query(
        "COPY LivesIn From '/Users/lc/Developer/kuzu/dataset/demo-db/csv/lives-in.csv'"
    )
    print(result)
    result = try conn.query(
        "MATCH (u:User)-[l:LivesIn]->(c:City) RETURN u.name, c.name"
    )
    while result.hasNext() {
        let tuple = try result.getNext()
        print(tuple)
    }

    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

@Test func testGds() async throws {
    let db = try Kuzu.Database()
    let conn = try Kuzu.Connection(db)
    var result = try conn.query(
        "CREATE NODE TABLE Node(id STRING PRIMARY KEY);"
    )
    print(result)
    result = try conn.query(
        "CREATE REL TABLE Edge(FROM Node to Node, id INT64);"
    )
    print(result)
    result = try conn.query(
        """
                            CREATE (u0:Node {id: 'A'}),
                                    (u1:Node {id: 'B'}),
                                    (u2:Node {id: 'C'}),
                                    (u3:Node {id: 'D'}),
                                    (u4:Node {id: 'E'}),
                                    (u5:Node {id: 'F'}),
                                    (u6:Node {id: 'G'}),
                                    (u7:Node {id: 'H'}),
                                    (u8:Node {id: 'I'}),
                                    (u0)-[:Edge {id:0}]->(u1),
                                    (u1)-[:Edge {id:1}]->(u2),
                                    (u5)-[:Edge {id:2}]->(u4),
                                    (u6)-[:Edge {id:3}]->(u4),
                                    (u6)-[:Edge {id:4}]->(u5),
                                    (u6)-[:Edge {id:5}]->(u7),
                                    (u7)-[:Edge {id:6}]->(u4),
                                    (u6)-[:Edge {id:7}]->(u5)
        """
    )
    print(result)
    result = try conn.query("CALL project_graph('Graph', ['Node'], ['Edge']);")
    print(result)
    result = try conn.query(
        "CALL weakly_connected_components('Graph') RETURN group_id, collect(node.id);"
    )
    print(result)
}

@Test func testParam() async throws {
    let db = try Kuzu.Database()
    let conn = try Kuzu.Connection(db)
    let preparedStatement = try conn.prepare("RETURN $1")
    var result = try conn.execute(
        preparedStatement,
        [
            "1": [
                [
                    "name": "Alice",
                    "age": 123,
                    "address": [
                        "country": "US",
                        "city": "New York",
                    ],
                ],
                [
                    "name": "Bob",
                    "age": 323,
                    "address": [
                        "country": "Canada",
                        "city": "Toronto",
                    ],
                ]
            ]
        ]
    )
    print(result)
    print(result.getColumnNames())
}
