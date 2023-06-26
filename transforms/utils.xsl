<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:olrc="http://uscode.house.gov"
  xmlns:functx="http://www.functx.com" xmlns:uslm="http://schemas.gpo.gov/xml/uslm" 
  xmlns:xpf="http://www.w3.org/2005/xpath-functions" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xs functx olrc uslm xpf map"
  version="3.0">
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Replace function for the numbers in the footnote counts</xd:p>
    </xd:desc>
    <xd:param name="arg"></xd:param>
    <xd:param name="changeFrom">The strings to change from</xd:param>
    <xd:param name="changeTo">The strings to change to</xd:param>
    <xd:return></xd:return>
  </xd:doc>
  <xsl:function name="functx:replace-multi" as="xs:string?"
    xmlns:functx="http://www.functx.com">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="changeFrom" as="xs:string*"/>
    <xsl:param name="changeTo" as="xs:string*"/>
    
    <xsl:sequence select="
      if (count($changeFrom) > 0)
      then functx:replace-multi(
      replace($arg, $changeFrom[1],
      functx:if-absent($changeTo[1],'')),
      $changeFrom[position() > 1],
      $changeTo[position() > 1])
      else $arg
      "/>
    
  </xsl:function>
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Returns the first argument if it is not empty; returns the second argument
        otherwise.</xd:p>
    </xd:desc>
    <xd:param name="arg"></xd:param>
    <xd:param name="value"></xd:param>
    <xd:return></xd:return>
  </xd:doc>
  <xsl:function name="functx:if-absent" as="item()*"
    xmlns:functx="http://www.functx.com">
    <xsl:param name="arg" as="item()*"/>
    <xsl:param name="value" as="item()*"/>
    
    <xsl:sequence select="
      if (exists($arg))
      then $arg
      else $value
      "/>
    
  </xsl:function>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Create the map of merged provisions.  There can be a non-merged provision
        and a merged provision that start with the same id. The items created are in the order:
      key = first id in merge, value is second id:target:publicComment:docMeta</xd:p>
    </xd:desc>
    <xd:param name="mappedJson">The input JSON, converted into the default XML representation.</xd:param>
  </xd:doc>
  <xsl:function name="olrc:createMergedMap">
    <xsl:param name="mappedJson"  as="element()*"/>      
    <xsl:variable name="id-merged" as="map(xs:string, xs:string*)">
      <xsl:map>
        <xsl:choose>
          <xsl:when test="matches($user, 'bluelinefinal')">
            <xsl:for-each-group
              select="
              $mappedJson//xpf:string[@key = 'id'][contains(., '-m-')]
              [not(normalize-space(../xpf:string[@key = 'target']) = '')]"
              group-by="substring-before(., '-m-')">
              <xsl:map-entry key="current-grouping-key()"
                select="
                substring-after(., '-m-'), normalize-space(../xpf:string[@key = 'target']),
                normalize-space(string(../xpf:string[@key = 'publicComment'])),
                normalize-space(string(../xpf:map[@key='docMeta']/xpf:string[@key='otherDesignation']))"
              />
            </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each-group
              select="
              $mappedJson//xpf:string[@key = 'id'][contains(., '-m-')]
              [not(normalize-space(../xpf:string[@key = 'targetSection']) = '')]"
              group-by="substring-before(., '-m-')">
              <xsl:map-entry key="current-grouping-key()"
                select="
                substring-after(., '-m-'), normalize-space(string(../xpf:string[@key = 'targetSection'])),
                normalize-space(string(../xpf:string[@key = 'publicComment'])),
                normalize-space(string(../xpf:map[@key='docMeta']/xpf:string[@key='otherDesignation']))"
              />
            </xsl:for-each-group>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:map>
    </xsl:variable>
    <xsl:sequence select="$id-merged"/>
  </xsl:function>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Test the merged list returns the expected values.</xd:p>
    </xd:desc>
    <xd:param name="mappedJson"></xd:param>
  </xd:doc>
  <xsl:function name="olrc:testMergedList">
    <xsl:param name="mappedJson"  as="element()+"/>      

    <output>
      <xpf:map>
        <xsl:for-each select="map:keys(olrc:createMergedMap($mappedJson))">
          <xsl:variable name="currentKey" select="." as="xs:string"/>
          <xpf:key><xsl:value-of select="."/></xpf:key>
          <xpf:value><xsl:value-of select="map:get(olrc:createMergedMap($mappedJson),.)" separator=":"/></xpf:value>
        </xsl:for-each>
      </xpf:map>
    </output>
    
  </xsl:function>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Get the bill type and number from the complete billnumber.</xd:p>
    </xd:desc>
    <xd:param name="billnumber"></xd:param>
  </xd:doc>
  <xsl:function name="olrc:mapBillNumber">
    <xsl:param name="billnumber" as="xs:string" required="yes"/>
    
    <xsl:variable name="parts" select="analyze-string($billnumber,'(\d+)([a-z]+)(\d+)(enr)')" as="element()"/>
    <xsl:message use-when="false()" select="$parts"/>
    <xsl:variable name="type" as="xs:string" select="$parts/xpf:match/xpf:group[@nr=2]"/>
    <xsl:sequence>
      <xsl:choose>
        <xsl:when test="$type='hr'"><xsl:text>H. R. </xsl:text></xsl:when>
        <xsl:when test="$type='s'"><xsl:text>S. </xsl:text></xsl:when>
        <xsl:when test="$type='hjres'"><xsl:text>H. J. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sjres'"><xsl:text>S. J. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='hconres'"><xsl:text>H. CON. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sconres'"><xsl:text>S. CON. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='hres'"><xsl:text>H. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sres'"><xsl:text>S. RES. </xsl:text></xsl:when>
      </xsl:choose>
    </xsl:sequence>
    <xsl:value-of select="$parts/xpf:match/xpf:group[@nr=3]"></xsl:value-of>
  </xsl:function>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Get the congress number from the complete billnumber.</xd:p>
    </xd:desc>
    <xd:param name="billnumber"></xd:param>
  </xd:doc>
  <xsl:function name="olrc:getCongressNumber">
    <xsl:param name="billnumber" as="xs:string" required="yes"/>
    
    <xsl:variable name="parts" select="analyze-string($billnumber,'(\d+)([a-z]+)(\d+)(enr)')" as="element()"/>
    <xsl:message use-when="false()" select="$parts"/>
    <xsl:value-of select="$parts/xpf:match/xpf:group[@nr=1]"></xsl:value-of>
  </xsl:function>
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Get the document number from the complete billnumber.</xd:p>
    </xd:desc>
    <xd:param name="billnumber"></xd:param>
  </xd:doc>
  <xsl:function name="olrc:getDocNumber">
    <xsl:param name="billnumber" as="xs:string" required="yes"/>
    
    <xsl:variable name="parts" select="analyze-string($billnumber,'(\d+)([a-z]+)(\d+)(enr)')" as="element()"/>
    <xsl:message use-when="false()" select="$parts"/>
    <xsl:value-of select="$parts/xpf:match/xpf:group[@nr=3]"></xsl:value-of>
  </xsl:function>  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Get the document type from the complete billnumber.</xd:p>
    </xd:desc>
    <xd:param name="billnumber"></xd:param>
  </xd:doc>
  <xsl:function name="olrc:getDocType">
    <xsl:param name="billnumber" as="xs:string" required="yes"/>
    
    <xsl:variable name="parts" select="analyze-string($billnumber,'(\d+)([a-z]+)(\d+)(enr)')" as="element()"/>
    <xsl:message use-when="false()" select="$parts"/>
    <xsl:variable name="type" as="xs:string" select="$parts/xpf:match/xpf:group[@nr=2]"/>
    <xsl:sequence>
      <xsl:choose>
        <xsl:when test="$type='hr'"><xsl:text>H. R. </xsl:text></xsl:when>
        <xsl:when test="$type='s'"><xsl:text>S. </xsl:text></xsl:when>
        <xsl:when test="$type='hjres'"><xsl:text>H. J. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sjres'"><xsl:text>S. J. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='hconres'"><xsl:text>H. CON. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sconres'"><xsl:text>S. CON. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='hres'"><xsl:text>H. RES. </xsl:text></xsl:when>
        <xsl:when test="$type='sres'"><xsl:text>S. RES. </xsl:text></xsl:when>
      </xsl:choose>
    </xsl:sequence>
  </xsl:function>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Get the session number from the phrase</xd:p>
    </xd:desc>
    <xd:param name="input">session phrase</xd:param>
  </xd:doc>
  <xsl:function name="olrc:getSession">
    <xsl:param name="input" as="xs:string"/>
    <xsl:sequence>
      <xsl:choose>
        <xsl:when test="upper-case($input)='AT THE FIRST SESSION'">1</xsl:when>
        <xsl:when test="upper-case($input)='AT THE SECOND SESSION'">2</xsl:when>
      </xsl:choose>
    </xsl:sequence>
  </xsl:function>
</xsl:stylesheet>