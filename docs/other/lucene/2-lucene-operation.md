[TOC]

# Lucene Operation 

## 1.建立索引

```java
public static void generateIndex() throws IOException {
    String filePath = "D:\\luccene\\file";
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 内存存储
    //Directory directory1 = new RAMDirectory();
    // 指定了writer的配置
    IndexWriterConfig writerConfig = new IndexWriterConfig(Version.LUCENE_4_10_4, new IKAnalyzer());
    IndexWriter indexWriter = new IndexWriter(directory, writerConfig);
    // 遍历指定目录中的文件
    File file = new File(filePath);
    File[] files = file.listFiles();
    // 一个文件对应一个document
    for (int i=0;i<files.length;i++){
        File fileTmp = files[i];
        Document document = new Document();
        // 记录文件的名字
        Field fileName = new StringField("fileName",fileTmp.getName(), Field.Store.YES);
        // 记录文件的大小
        Field fileSize = new LongField("fileSize", FileUtils.sizeOf(fileTmp), Field.Store.YES);
        // 记录文件的内容
        Field fileContent = new TextField("fileContent",FileUtils.readFileToString(fileTmp,"UTF-8"), Field.Store.YES);
        document.add(fileName);
        document.add(fileSize);
        document.add(fileContent);
        indexWriter.addDocument(document);
    }
    indexWriter.close();
}
```

打印:

```java
public static void printResult(IndexSearcher searcher,Query query) throws IOException {
    // 获取查询到的文档
    TopDocs topDocs = searcher.search(query, 100);
    // 打印查询条件
    log.debug(query.toString());
    ScoreDoc[] scoreDocs = topDocs.scoreDocs;
    for (int i = 0; i < scoreDocs.length; i++) {
        // 获取到文件索引
        int doc = scoreDocs[i].doc;
        // 获取文档内容
        Document document = searcher.doc(doc);
        for (IndexableField field : document.getFields()) {
            String name = field.name();
            String value = field.stringValue();
            log.info("name = {}, value = {}",name,value);
        }
    }
}
```



## 2. 查询所有

```java
// 查询所有
    public static void QueryAll() throws IOException {
        String indexPath ="D:\\luccene\\index2";
        // index索引存储的地方
        Directory directory = FSDirectory.open(new File(indexPath));
        // 读取index
        IndexReader reader = DirectoryReader.open(directory);
        // searcher
        IndexSearcher searcher = new IndexSearcher(reader);
        // 查询条件
        Query query = new MatchAllDocsQuery();
        // 打印结果
        printResult(searcher,query);
        searcher.getIndexReader().close();
    }
```



## 3.按照条件查询

```java
// 按照条件查询
public static void QueryByFileName() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    // 按照指定的term条件进行查询,类似于:
    // select * from where fileName=lucene.txt
    Query query = new TermQuery(new Term("fileName","lucene.txt"));
    printResult(searcher,query);
    searcher.getIndexReader().close();
}
```



## 4. 按照大小查询

```java
// 按照大小查找
public static void queryRange() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    // 第一个true表示: 是否包含开始值
    // 第二个true表示: 是否包含结束值
    // 类似于:
    // select * from table where fileSize <= 1 and fileSize <= 1000
    Query query = NumericRangeQuery.newLongRange("fileSize",1L,1000L,true,true);
    printResult(searcher,query);
    searcher.getIndexReader().close();
}
```



## 5.联合查询

```java
// 联合查找
public static void queryMulti() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    // 联合查询。（名字起的有点 词不达意）
    BooleanQuery query = new BooleanQuery();
    TermQuery fileName = new TermQuery(new Term("fileName", "lucene.txt"));
    NumericRangeQuery<Long> fileSize = NumericRangeQuery.newLongRange("fileSize", 10L, 50L, true, true);
    // 此处的occur类似于 and or, select * from user_table where name="zhangsan" and age="20" 类似于此实例中的 and, 也就是两个条件
    // 是如何进行联合的
    query.add(fileName, BooleanClause.Occur.MUST);
    query.add(fileSize, BooleanClause.Occur.MUST);

    printResult(searcher,query);
    searcher.getIndexReader().close();
}
```



## 6. 通配符查询

```java
// 通配符查询
public static void queryWildcardQuery() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
	// 类似于:
    // select * from table where fileName like "lucene%" ;
    WildcardQuery query = new WildcardQuery(new Term("fileName","lucene*"));
    printResult(searcher,query);

    searcher.getIndexReader().close();
}
```



## 7.使用前缀查询

```java
// 使用前缀查询
public static void queryPrefixQuery() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    // 表示文件名字是 l (L)开头
    PrefixQuery query = new PrefixQuery(new Term("fileName", "l"));
    printResult(searcher,query);

    searcher.getIndexReader().close();
}
```



## 8. 多关键字查询

```java
// 多关键字查询
public static void queryPhraseQuery() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    PhraseQuery query = new PhraseQuery();
    // Exception in thread "main" java.lang.IllegalStateException: field "fileName" was indexed without
    // position data;cannot run PhraseQuery (term=lucene.txt)
    query.add(new Term("fileName","lucene.txt"));
    query.add(new Term("fileName","apache-lucene.txt"));

    printResult(searcher,query);

    searcher.getIndexReader().close();
}
```



## 9. 相近词语查询

```java
// 相近词语的搜索
//FuzzyQuery是一种模糊查询，它可以简单地识别两个相近的词语
public static void queryFuzzyQuery() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);

    FuzzyQuery query = new FuzzyQuery(new Term("fileContent","lucene"));
    printResult(searcher,query);
    searcher.getIndexReader().close();
}
```



## 10. 指定删除

```java
// 指定删除
public static void deleteByCondition() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    IndexWriterConfig writerConfig = new IndexWriterConfig(Version.LUCENE_4_10_4, new IKAnalyzer());
    IndexWriter indexWriter = new IndexWriter(directory, writerConfig);
	// 查询
    Query query = new TermQuery(new Term("fileName", "lucene.txt"));
    // 删除  fileName=lucene.txt的文件
    indexWriter.deleteDocuments(query);

    indexWriter.close();
}
```



## 11. 删除所有

```java
// 删除所有
public static void deletAll() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    IndexWriterConfig writerConfig = new IndexWriterConfig(Version.LUCENE_4_10_4, new IKAnalyzer());
    IndexWriter indexWriter = new IndexWriter(directory, writerConfig);
    // 删除所有
    indexWriter.deleteAll();
    indexWriter.close();
}
```



## 12.更新

```java
// 更新操作
public static void update() throws IOException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    IndexWriterConfig writerConfig = new IndexWriterConfig(Version.LUCENE_4_10_4, new IKAnalyzer());
    IndexWriter indexWriter = new IndexWriter(directory, writerConfig);
    Document document = new Document();
    Field fileN = new StringField("fileN","updateName", Field.Store.YES);
    Field fileC = new StringField("fileC","this is not apache lucene", Field.Store.YES);
    document.add(fileC);
    document.add(fileN);
    // 更新就是把原来的删除,新的写入
    indexWriter.updateDocument(new Term("fileName","apache-lucene.txt"),document);

    indexWriter.close();
}
```



## 13. QueryParse

```java
public static void queryParse() throws IOException, ParseException {
    String indexPath ="D:\\luccene\\index2";
    // index索引存储的地方
    Directory directory = FSDirectory.open(new File(indexPath));
    // 读取index
    IndexReader reader = DirectoryReader.open(directory);
    IndexSearcher searcher = new IndexSearcher(reader);
    String searchField="fileName";      // 要查询的字段
    // 1. 精确查找
    //String query = "lucene.txt";  // 精确查找 表示：fileName:lucene.txt
    String query = "lucene~";  // 模糊查找
    /**
         * 2. 分词查询
         * parser.parse("lucene.txt  apache.txt")
         * 空格表示或，即： fileName=lucene.txt or fileName=apache.txt
         *
         * 3.修改属性域
         * parser.parse("fileSize:20")
         * 此表示查询的是fileSize=20的文件
         *
         * 4.通配符匹配
         *  parser.parse("fileName:L*")
         *  parser.parse("fileName:L???")
         *  parser.setAllowLeadingWildcard(true); // lucene认为通配符在前的查询方式效率低,故要设置一下
         *  parser.parse("fileName:*k")
         *
         * 5.区间查找
         *  TO: 表示全部大写
         *  开区间: 不包含两个端点的值.(2,5)   2<x<5
         *  闭区间: 包含两个端点的值.[2,5]     2<=x<=5
         *  没有半开区间
         *  parser.parse("id:[1 TO 3]")
         *  parser.parse("id:{1 TO 3}")
         *  parser.parse("author:[M TO Z]")
         *
         * 区间无法对数值类型进行查询
         * parser.parse("size:[1 TO 1000]")
         *
         * 6.多条件查找
         * -: 必须不包含(排除)
         * +: 必须包含
         * // 查询author不好喊Mike 或 content 中包含my的所有条目
         *  parser.parse("-author:Mike + content:my")
         *
         * 7.and连接符
         * parser.parse("my and  mother")
         *
         * 8.短语查找
         * parser.parse("\"my and  mother\"")
         *
         * 9.距离查询
         * // ~2 表示词语之间包含两个词语
         *  parser.parse("\"my and  mother\"~2")
         *
         * 10.模糊匹配
         *  parser.parse("lucene~")
         */
    QueryParser queryParser = new QueryParser(searchField, new IKAnalyzer());
    Query parse = queryParser.parse(query);
    printResult(searcher,parse);
}
```



