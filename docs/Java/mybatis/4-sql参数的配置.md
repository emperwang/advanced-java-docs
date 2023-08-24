# mybatis sql语句参数设置

咱们这里在debug走一下那个参数的设置流程。这是debug使用的sql语句:

```java
// 接口函数    
User findById(Integer id);

// xml语句
<sql id="baseSql">
    id,name,age,address
</sql>

<select id="findById" resultMap="baseResultMap" parameterType="java.lang.Integer">
        SELECT <include refid="baseSql"/>
        FROM user WHERE id = #{id}
</select>

// 具体的调用函数
User user = userMapper.findById(1);
```

再看一下参数设置的操作流程:

```java
  private Statement prepareStatement(StatementHandler handler, Log statementLog) throws SQLException {
    Statement stmt;
    Connection connection = getConnection(statementLog);
    stmt = handler.prepare(connection, transaction.getTimeout());
      // 参数设置
    handler.parameterize(stmt);
    return stmt;
  }

  public void parameterize(Statement statement) throws SQLException {
    parameterHandler.setParameters((PreparedStatement) statement);
  }

	// 具体的设置参数
  public void setParameters(PreparedStatement ps) {
	// 获取参数映射
    List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
    if (parameterMappings != null) {
        // 遍历参数映射 进行参数设置
      for (int i = 0; i < parameterMappings.size(); i++) {
        ParameterMapping parameterMapping = parameterMappings.get(i);
        if (parameterMapping.getMode() != ParameterMode.OUT) {
          Object value;
          String propertyName = parameterMapping.getProperty();
          if (boundSql.hasAdditionalParameter(propertyName)) { 
            value = boundSql.getAdditionalParameter(propertyName);
          } else if (parameterObject == null) {
            value = null;
          } else if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
            value = parameterObject;
          } else {
            MetaObject metaObject = configuration.newMetaObject(parameterObject);
            value = metaObject.getValue(propertyName);
          }
            // 获取类型的处理函数
          TypeHandler typeHandler = parameterMapping.getTypeHandler();
          JdbcType jdbcType = parameterMapping.getJdbcType();
          if (value == null && jdbcType == null) {
            jdbcType = configuration.getJdbcTypeForNull();
          }
          try {// 具体的设置操作
            typeHandler.setParameter(ps, i + 1, value, jdbcType);
          } catch (TypeException e) {
            throw new TypeException("Could not set parameters for mapping: " + parameterMapping + ". Cause: " + e, e);
          } catch (SQLException e) {
            throw new TypeException("Could not set parameters for mapping: " + parameterMapping + ". Cause: " + e, e);
          }
        }
      }
    }
  }


  public void setParameter(PreparedStatement ps, int i, T parameter, JdbcType jdbcType) throws SQLException {
    if (parameter == null) {
      if (jdbcType == null) {
        throw new TypeException("JDBC requires that the JdbcType must be specified for all nullable parameters.");
      }
      try {
        ps.setNull(i, jdbcType.TYPE_CODE);
      } catch (SQLException e) {
        throw new TypeException("Error setting null for parameter #" + i + " with JdbcType " + jdbcType + " . " +  "Try setting a different JdbcType for this parameter or a different jdbcTypeForNull configuration property. " +  "Cause: " + e, e);
      }
    } else {
      try { // 因为参数不为null  故会执行这里
          // 因为参数类型是Integer类型,最终会调用IntegerTypeHandler
        setNonNullParameter(ps, i, parameter, jdbcType);
      } catch (Exception e) {
        throw new TypeException("Error setting non null for parameter #" + i + " with JdbcType " + jdbcType + " . " + "Try setting a different JdbcType for this parameter or a different configuration property. " + "Cause: " + e, e);
      }
    }
  }

	// 具体的设置
  public void setNonNullParameter(PreparedStatement ps, int i, Integer parameter, JdbcType jdbcType)
      throws SQLException {
      // 这里就是调用mysql驱动了
    ps.setInt(i, parameter);
  }

```

按照debug步骤，截个图看看，不过还是希望大家自己动手debug一下:

![](debug-setParameter1.png)

![](debug-setParameter2.png)

![](debug-setParameter3.png)

![](debug-setParameter4.png)

![](debug-setParameter5.png)

![](debug-setParameter6.png)