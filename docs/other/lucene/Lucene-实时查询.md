[TOC]

# 近实时查询

```java
public class NRTSearch {
    String filePath = "D:\\luccene\\file";
    String indexPath ="D:\\luccene\\index2";

    private Directory directory ;
    private IndexWriter writer;
    private TrackingIndexWriter trackingIndexWriter;
    private ReferenceManager<IndexSearcher> referenceManager;
    private ControlledRealTimeReopenThread<IndexSearcher> crt;

    public NRTSearch(){
        try{
            directory = FSDirectory.open(new File(indexPath));
            IndexWriterConfig writerConfig = new IndexWriterConfig(Version.LUCENE_4_10_4, new IKAnalyzer());
            writer = new IndexWriter(directory,writerConfig);
            // 主要是这里，追踪IndexSearcher
            trackingIndexWriter = new TrackingIndexWriter(writer);
            referenceManager = new SearcherManager(writer,true,new SearcherFactory());
            // 0.025 ~5.0s之间重启一次线程, 实践得数
            crt = new ControlledRealTimeReopenThread<>(trackingIndexWriter,referenceManager,
                                                       5.0,0.025);
            crt.setDaemon(true);  // 设置为后台服务
            crt.setName("Index-update-To-Disk"); // 线程name
            crt.start();
        }catch (Exception e){
            log.error("msg :{}",e.getMessage());
        }
    }

    /**
     *  定期提交内存中的索引到硬盘，防止丢失
     */
    public void commit(){
        try {
            writer.commit();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     *  建立索引
     * @param isNew
     */
    public void index(boolean isNew){
        if (isNew){
            try {
                // 遍历指定目录中的文件
                File file = new File(filePath);
                File[] files = file.listFiles();
                for (int i = 0; i < files.length; i++) {
                    File fileTmp = files[i];
                    Document document = new Document();
                    Field fileName = new StringField("fileName", fileTmp.getName(), Field.Store.YES);
                    Field fileSize = new LongField("fileSize", FileUtils.sizeOf(fileTmp), Field.Store.YES);
                    Field fileContent = new TextField("fileContent", FileUtils.readFileToString(fileTmp,
                                                                                                "UTF-8"), Field.Store.YES);
                    document.add(fileName);
                    document.add(fileSize);
                    document.add(fileContent);
                    trackingIndexWriter.addDocument(document);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }finally {
                commit();
            }
        }
    }
    // 获取indexSearch
    public IndexSearcher getSearch(){
        IndexSearcher searcher = null;
        try{
            if (searcher == null){
                referenceManager.maybeRefresh();
                searcher = referenceManager.acquire();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        if (searcher == null){
            log.error("error ......");
        }
        return searcher;
    }

    public static void printResult(IndexSearcher searcher,Query query) throws IOException {
        TopDocs topDocs = searcher.search(query, 100);
        log.debug(query.toString());
        ScoreDoc[] scoreDocs = topDocs.scoreDocs;
        for (int i = 0; i < scoreDocs.length; i++) {
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

    public void QueryAll() throws IOException {
        IndexSearcher search = getSearch();
        Query query = new MatchAllDocsQuery();
        printResult(search,query);
    }
```

