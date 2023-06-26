<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================= -->
<!-- PROJECT    OLRC Classification                                -->
<!-- CLIENT     Office of the Law Revision Counsel                 -->
<!-- DEVELOPER  Xcential Corporation                               -->
<!-- FILE       addClassification.xsl                              -->
<!-- PURPOSE    Run the code that reads the locations and 
                content of classifications from one file and 
                add them to the USLM                               -->
<!-- ============================================================= -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.gpo.gov/xml/uslm"
    xmlns:uslm="http://schemas.gpo.gov/xml/uslm" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:functx="http://www.functx.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xpf="http://www.w3.org/2005/xpath-functions" xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:olrc="http://uscode.house.gov"
    exclude-result-prefixes="#all"
    version="3.0">

    <!-- Include the functions and utilities -->
    <xsl:include href="utils.xsl"/>
    <xsl:include href="notes.xsl"/>
    <xsl:include href="merged.xsl"/>
    <xsl:include href="moveTrailing.xsl"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output encoding="UTF-8" method="xml"/>

    <!-- pass the input JSON file name -->
    <xsl:param name="inputJSON" as="xs:string" select="''"/>
    <xsl:param name="inputJsonFile" as="xs:anyURI" select="xs:anyURI($inputJSON)"/>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Read in the JSON file and map to XML.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="json">
        <xsl:choose>
            <xsl:when test="$inputJsonFile">
                <xsl:try>
                    <xsl:sequence select="json-to-xml(unparsed-text($inputJsonFile))"/>
                    <xsl:catch>
                        <xsl:message>Errors with input JSON file: 
                            Error code: <xsl:value-of select="$err:code"/> 
                            Reason: <xsl:value-of select="$err:description"/>
                        </xsl:message>
                    </xsl:catch>
                </xsl:try>
            </xsl:when>
            <xsl:otherwise><xsl:message>File '<xsl:value-of select="$inputJSON"/>' does not exist or is the empty string.</xsl:message></xsl:otherwise>
        </xsl:choose>
        
    </xsl:variable>
    <xsl:variable name="user"
        select="
        if ($json/xpf:map/xpf:string[@key = 'user']) 
        then ($json/xpf:map/xpf:string[@key = 'user'])
        else ''"
        as="xs:string"/>
    <xsl:variable name="meta"
        select="
        if ($json/xpf:map/xpf:map[@key = 'bill_meta']) 
        then ($json/xpf:map/xpf:map[@key = 'bill_meta'])
        else ()"
        as="element()*"/>
    <xsl:variable name="billnumber" as="xs:string"
        select="
        if ($json//xpf:map/xpf:string[@key = 'billnumber'])
        then ($json//xpf:map/xpf:string[@key = 'billnumber'])
        else ''"/>

    <!-- Set up default transform -->
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:mode on-no-match="shallow-copy" name="addFootnotes"/>
    <xsl:mode on-no-match="shallow-copy" name="createFootnoteContent"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Starting template. The stylesheet location is /css/...</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:text>&#xa;</xsl:text>
        <xsl:processing-instruction name="xml-stylesheet">type="text/css" href="/css/uslm.css"</xsl:processing-instruction>
        <xsl:text>&#xa;</xsl:text>
        <xsl:processing-instruction name="xml-stylesheet">type="text/css" href="/css/uslm-classification.css"</xsl:processing-instruction>
        <xsl:text>&#xa;</xsl:text>
        <xsl:variable name="phase0">
            <xsl:apply-templates/>
        </xsl:variable>
        <xsl:variable name="phaseAddFootnotes">
            <xsl:apply-templates mode="addFootnotes" select="$phase0"/>
        </xsl:variable>
        <xsl:sequence select="$phaseAddFootnotes"/>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>The pagenum attribute is used only for the application and is not part of the USLM
                schema; delete. The same applies to the data-lt-installed attribute.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="attribute::pagenum | attribute::data-lt-installed"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Change the schema version to one that includes sidenote and page elements.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="attribute::xsi:schemaLocation">
        <xsl:attribute name="xsi:schemaLocation">http://schemas.gpo.gov/xml/uslm uslm-2.0.12.xsd</xsl:attribute>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Turn page PIs into elements for easier styling. There is a separate template
            for the first page PI, which is outside the main content and moved to the preface. </xd:p>
        </xd:desc>
        <xd:param name="billnumber">bill number information from the JSON</xd:param>
    </xd:doc>
    <xsl:template match="processing-instruction(page)[not(ancestor::xhtml:table)]
        [ancestor::uslm:main]">
        <xsl:param name="billnumber" as="xs:string" select="$billnumber" tunnel="yes"/>
        <xsl:text>&#xa;</xsl:text>
        <page>
            <xsl:attribute name="id">page<xsl:value-of select="."/></xsl:attribute>
            <xsl:choose>
                <xsl:when test="ancestor::*/uslm:meta/uslm:docNumber">
                    <xsl:value-of select="replace(ancestor::*/uslm:preface/dc:type,' ','') || ' ' || ancestor::*/uslm:meta/uslm:docNumber"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="if ($billnumber) 
                    then (olrc:mapBillNumber($billnumber))
                    else ()"/></xsl:otherwise>
            </xsl:choose>
            <xsl:text>—</xsl:text>
            <xsl:value-of select="."/>
        </page>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Delete the first page PI (outside the main element) in the original location</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction(page)[not(ancestor::uslm:main)]"/>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Move the first page PI (outside the main element) into the preface to 
            make it valid USLM2.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:preface">
        <preface>
            <xsl:apply-templates select="@*"/>
            <xsl:text>&#xa;</xsl:text>
            <page>
                <xsl:attribute name="id">page1</xsl:attribute>
                <xsl:if test="../uslm:meta/uslm:docNumber">
                    <xsl:value-of select="replace(../uslm:preface/dc:type,' ','') || ' ' || ../uslm:meta/uslm:docNumber"/>
                </xsl:if>
                <xsl:text>—1</xsl:text>
            </page>
            <xsl:apply-templates select="node()"/>
        </preface>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>If the meta and preface information is not already in the bill, add it from the JSON.</xd:p>
        </xd:desc>
        <xd:param name="meta">general meta information from the JSON bill_meta</xd:param>
        <xd:param name="billnumber">bill number information from the JSON</xd:param>
    </xd:doc>
    <xsl:template match="uslm:bill">
        <xsl:param name="meta" as="element()*" select="$meta" tunnel="yes"/>
        <xsl:param name="billnumber" as="xs:string" select="$billnumber" tunnel="yes"/>
        <bill>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(uslm:meta)">
                <xsl:call-template name="createMetaElement">
                    <xsl:with-param name="meta" select="$meta" as="element()"/>
                    <xsl:with-param name="billnumber" select="$billnumber" as="xs:string"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </bill>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Create the meta and preface elements if they don't exist</xd:p>
        </xd:desc>
        <xd:param name="meta">Input meta information from the JSON</xd:param>
        <xd:param name="billnumber">Input billnumber information from the JSON</xd:param>
    </xd:doc>
    <xsl:template name="createMetaElement">
        <xsl:param name="meta" as="element()*" select="$meta"/>
        <xsl:param name="billnumber" as="xs:string" select="$billnumber"/>
        <xsl:variable name="congress" select="olrc:getCongressNumber($billnumber)"/>
        <xsl:variable name="docType" select="olrc:getDocType($billnumber)"/>
        <xsl:variable name="docNum" select="olrc:getDocNumber($billnumber)"/>
        <xsl:variable name="session" select="olrc:getSession($meta/xpf:string[@key='sessionphrase'])"/>
        <meta>
            <xsl:attribute name="class">addedMeta</xsl:attribute><xsl:text>&#xa;</xsl:text>
            <docNumber><xsl:value-of select="$docNum"/></docNumber><xsl:text>&#xa;</xsl:text>
            <citableAs><xsl:value-of select="$billnumber"/></citableAs><xsl:text>&#xa;</xsl:text>
            <citableAs><xsl:value-of select="$congress || ' ' || replace($docType,' ','') || ' ' || $docNum|| ' ENR'"/></citableAs><xsl:text>&#xa;</xsl:text>
            <dc:publisher>United States Government Publishing Office</dc:publisher><xsl:text>&#xa;</xsl:text>
            <dc:format>text/xml</dc:format><xsl:text>&#xa;</xsl:text>
            <dc:language>EN</dc:language><xsl:text>&#xa;</xsl:text>
            <dc:rights>Pursuant to Title 17 Section 105 of the United States Code, this file is not subject to copyright protection and is in the public domain.</dc:rights><xsl:text>&#xa;</xsl:text>
            <docStage>ENR</docStage><xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="createProcessorInfo"/>
            <congress><xsl:value-of select="$congress"/></congress><xsl:text>&#xa;</xsl:text>
            <session><xsl:value-of select="$session"/></session><xsl:text>&#xa;</xsl:text>
            <publicPrivate>public</publicPrivate><xsl:text>&#xa;</xsl:text>
        </meta><xsl:text>&#xa;</xsl:text>
        <preface>
            <xsl:attribute name="class">addedPreface</xsl:attribute><xsl:text>&#xa;</xsl:text>
            <page>
                <xsl:attribute name="id">page1</xsl:attribute>
                <xsl:value-of select="if ($billnumber) 
                    then (olrc:mapBillNumber($billnumber))
                    else ()"/><xsl:text>—1</xsl:text>
            </page>
            <dc:type><xsl:value-of select="olrc:mapBillNumber($billnumber)[1]"/></dc:type>
            <docNumber><xsl:value-of select="olrc:mapBillNumber($billnumber)[2]"/></docNumber><xsl:text>&#xa;</xsl:text>
            <congress><xsl:attribute name="value" select="$congress"/><xsl:value-of select="$meta/xpf:string[@key='congressphrase']"/></congress><xsl:text>&#xa;</xsl:text>
            <session><xsl:attribute name="value" select="$session"/><xsl:value-of select="$meta/xpf:string[@key='sessionphrase']"/></session><xsl:text>&#xa;</xsl:text>
        </preface><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Split the table if a page PI is contained within it. </xd:p>
        </xd:desc>
        <xd:param name="billnumber">bill number information from the JSON</xd:param>
    </xd:doc>
    <xsl:template match="xhtml:table[xhtml:tbody[processing-instruction(page)]]">
        <xsl:param name="billnumber" as="xs:string" select="$billnumber" tunnel="yes"/>
        <!-- complete the tbody before the first page PI -->
        <xhtml:table>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()[following-sibling::xhtml:tbody]"/>
            <xhtml:tbody>
                <xsl:apply-templates select="xhtml:tbody/@*"/>
                <xsl:apply-templates
                    select="
                        xhtml:tbody/node()[not(preceding-sibling::processing-instruction(page))
                        and not(self::processing-instruction(page))]"
                />
            </xhtml:tbody>
        </xhtml:table>
        <xsl:for-each-group select="xhtml:tbody/node()"
            group-starting-with="processing-instruction(page)">
            <xsl:choose>
                <xsl:when test="position() gt 1">
                    <xsl:text>&#xa;</xsl:text>
                    <page>
                        <xsl:attribute name="id">page<xsl:value-of select="."/></xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="ancestor::*/uslm:meta/uslm:docNumber">
                                <xsl:value-of select="replace(ancestor::*/uslm:preface/dc:type,' ','') || ' ' || ancestor::*/uslm:meta/uslm:docNumber"/>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="if ($billnumber) 
                                then (olrc:mapBillNumber($billnumber))
                                else ()"/></xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>—</xsl:text>
                        <xsl:value-of select="."/>
                    </page>
                    <!-- copy the table start (colgroups etc, thead) to the beginning of the new table -->
                    <xhtml:table>
                        <xsl:apply-templates select="../../@*"/>
                        <xsl:apply-templates select="../../node()[following-sibling::xhtml:tbody]"/>
                        <xhtml:tbody>
                            <xsl:apply-templates select="../@*"/>
                            <xsl:apply-templates
                                select="current-group()[not(self::processing-instruction(page))]"/>
                        </xhtml:tbody>
                    </xhtml:table>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Remove existing source stylesheets (e.g. billres.xsl).</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('xml-stylesheet')"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Remove the class OLRCPrint, since it is no longer used in the stylesheets.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@class[. = 'OLRCPrint']"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Add sidenotes for the various pieces of classification information. The role
                attribute is used to give more details for the CSS styling. Type would be an
                alternative attribute but the values would need to be added to the schema.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:num">
        <num>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="map:contains($id-target, ../@id)">
                <xsl:call-template name="createTargetSidenote">
                    <xsl:with-param name="targetMap" select="$id-target"/>
                    <xsl:with-param name="locationId" select="../@id"/>
                    <xsl:with-param name="targetInFootnoteMap" select="$id-showTargetInFootnote"/>
                    <xsl:with-param name="docMetaMap" select="$id-docMeta"/>
                </xsl:call-template>
            </xsl:if>
            <!-- The merged id is of the form {start-id}-m-{end-id}, the key in the map
        uses the start-id -->
            <xsl:if test="map:contains($id-merged, ../@id)">
                <xsl:value-of select="../@id" use-when="false()"/>
                <xsl:call-template name="mergedProvisions">
                    <xsl:with-param name="id-merged" select="$id-merged"/>
                    <xsl:with-param name="mergeId" select="string(../@id)" as="xs:string"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:if test="map:contains($id-publicComments, ../@id)">
                <xsl:variable name="publicComment" select="map:get($id-publicComments, ../@id)"
                    as="xs:string"/>
                <sidenote topic="olrcClassification" role="publicComment">
                    <xsl:analyze-string select="$publicComment" regex="\\n">
                        <xsl:matching-substring>
                            <br/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:sequence select="."/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </sidenote>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </num>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Delete empty sidenotes and notes from the original document.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="uslm:sidenote[normalize-space(.) = ''] | uslm:note[normalize-space(.) = '']"/>


    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>In the case where the entire bill is classified 'out', the target is on the main
                element, not a num element. This version is for when the id attribute on the main element
            matches that found in the JSON. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:main[@id][map:contains($id-target, @id) or map:contains($id-docMeta, @id)]">
        <main>
            <xsl:apply-templates select="@*"/>
            <xsl:call-template name="createTargetSidenote">
                <xsl:with-param name="targetMap" select="$id-target"/>
                <xsl:with-param name="locationId" select="@id"/>
                <xsl:with-param name="targetInFootnoteMap" select="$id-showTargetInFootnote"/>
                <xsl:with-param name="docMetaMap" select="$id-docMeta"/>
            </xsl:call-template>
            <xsl:if test="map:contains($id-publicComments, @id)">
                <xsl:variable name="publicComment" select="map:get($id-publicComments, @id)"
                    as="xs:string"/>
                <sidenote topic="olrcClassification" role="publicComment">
                    <xsl:analyze-string select="$publicComment" regex="\\n">
                        <xsl:matching-substring>
                            <br/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:sequence select="."/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </sidenote>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </main>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>In the case where the entire bill is classified 'out', the target is on the main
                element, not a num element. This version is for when the id attribute on the main element
                does not match that found in the JSON. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:main[@id][not(map:contains($id-target, @id) or map:contains($id-docMeta, @id))]">
        <main>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="$json//xpf:map[@key='data']/xpf:map/xpf:string[@key='identifier']='/'">
                <!-- copy the value of the id attribute that matches the identifier '/' (the main element)
                and use that to do all the matching -->
                <xsl:variable name="pseudo-id" as="xs:string" 
                    select="$json//xpf:map[@key='data']/xpf:map[xpf:string[@key='identifier']='/']/xpf:string[@key='id']"/>
                <xsl:call-template name="createTargetSidenote">
                    <xsl:with-param name="targetMap" select="$id-target"/>
                    <xsl:with-param name="locationId" select="$pseudo-id"/>
                    <xsl:with-param name="targetInFootnoteMap" select="$id-showTargetInFootnote"/>
                    <xsl:with-param name="docMetaMap" select="$id-docMeta"/>
                </xsl:call-template>
                <xsl:if test="map:contains($id-publicComments, $pseudo-id)">
                    <xsl:variable name="publicComment" select="map:get($id-publicComments, $pseudo-id)"
                        as="xs:string"/>
                    <sidenote topic="olrcClassification" role="publicComment">
                        <xsl:analyze-string select="$publicComment" regex="\\n">
                            <xsl:matching-substring>
                                <br/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:sequence select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </sidenote>
                </xsl:if>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </main>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Find the target string and identifier for each granule.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="id-target" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:choose>
                <xsl:when test="matches($user, 'bluelinefinal')">
                    <xsl:for-each
                        select="$json//xpf:map[not(normalize-space(xpf:string[@key = 'target']) = '')]">
                        <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                            select="normalize-space(./xpf:string[@key = 'target'])"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each
                        select="$json//xpf:map[not(normalize-space(xpf:string[@key = 'targetSection']) = '')]">
                        <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                            select="normalize-space(./xpf:string[@key = 'targetSection'])"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:map>
    </xsl:variable>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Find the stamps (TU, PN, CO) for each granule.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="id-docMeta" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:choose>
                <xsl:when test="matches($user, 'bluelinefinal')">
                    <xsl:for-each
                        select="$json//xpf:map[not(normalize-space(xpf:string[@key = 'target']) = '')][xpf:map[@key = 'docMeta'][not(normalize-space(xpf:string[@key = 'otherDesignation']) = '')]]">
                        <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                            select="normalize-space(./xpf:map[@key = 'docMeta']/xpf:string[@key = 'otherDesignation'])"
                        />
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each
                        select="$json//xpf:map[not(normalize-space(xpf:string[@key = 'targetSection']) = '')][xpf:map[@key = 'docMeta'][not(normalize-space(xpf:string[@key = 'otherDesignation']) = '')]]">
                        <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                            select="normalize-space(./xpf:map[@key = 'docMeta']/xpf:string[@key = 'otherDesignation'])"
                        />
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:map>
    </xsl:variable>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Find the targets to show in footnotes for each granule.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="id-showTargetInFootnote" as="map(xs:string, xs:boolean)">
        <xsl:map>
            <xsl:for-each select="$json//xpf:map[xpf:boolean[@key = 'showTargetInFootnote']]">
                <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                    select="xs:boolean(xpf:boolean[@key = 'showTargetInFootnote'])"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Find the publicComments for each granule.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="id-publicComments" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:for-each
                select="$json//xpf:map[not(normalize-space(xpf:string[@key = 'publicComment']) = '')][xpf:string[@key = 'publicComment']]">
                <xsl:map-entry key="normalize-space(./xpf:string[@key = 'id'])"
                    select="string(./xpf:string[@key = 'publicComment'])"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>The merged id is of the form {start-id}-m-{end-id}, the key in the map
                uses the start-id</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="id-merged" select="olrc:createMergedMap($json/*)"/>


    <!-- move public comments and long targets into footnotes in second phase -->

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>The sidenotes have role="target", role="longTarget", or class="out". Those with
                longTarget have the target content replaced by a superscript letter. These sidenotes
                can be followed by comment sidenotes. These are replaced by superscript
            numbers. </xd:p>
            <xd:p>Add the 'CO' class to the 'CO'-stamped sidenotes to change their styling. </xd:p>
            <xd:p>Add superscripts for footnote references, if the document contains more than one page.</xd:p>
            <xd:p>Two different formats: 1 if preceding siblings are comments, a if classifications.
                When the sidenotes are in the num element, the inline sup should also be inside the 
                num element.</xd:p>
            <xd:p>The target (classification) is not always in the footnote; longTarget is</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="uslm:sidenote[@topic = 'olrcClassification'][contains(@role, 'arget') or contains(@class, 'out')]
        [not(following-sibling::uslm:num[uslm:marker][uslm:sidenote])][normalize-space(.)!='']"
        mode="addFootnotes">
        <xsl:value-of select="'sidenote target 548'" use-when="false()"/>
        <sidenote>
            <xsl:apply-templates select="@*[not(name() = 'role')][not(name() = 'note')]" mode="#current"/>
            <xsl:choose>
                <xsl:when test="@role">
                    <xsl:attribute name="role">
                        <xsl:value-of select="@role"/>
                        <xsl:value-of
                            select="
                                if (following-sibling::uslm:sidenote[contains(@role, 'publicComment')][normalize-space(.)!=''])
                                then
                                    (', publicComment')
                                else
                                    ()"
                        />
                    </xsl:attribute>
                </xsl:when>
                <xsl:when
                    test="not(@role) and following-sibling::uslm:sidenote[contains(@role, 'publicComment')][normalize-space(.)!='']">
                    <xsl:attribute name="role">
                        <xsl:value-of select="'publicComment'"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="(contains(@class, 'out') or contains(@role, 'target'))
               ">
                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:if>
            <xsl:if test="contains(@role, 'longTarget')">
                <sup><xsl:number format="a"
                    value="count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                    [contains(@role, 'longTarget')]
                    [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                    [if (following::uslm:page) 
                    then (following::uslm:page[1] = current()/following::uslm:page[1])
                    else (true())])+1"
                /></sup>
            </xsl:if>
            <xsl:if test="contains(@role, 'longTarget') and following-sibling::uslm:sidenote[contains(@role, 'publicComment')][normalize-space(.)!='']">
                <sup>,</sup>
            </xsl:if>
            <xsl:if test="following-sibling::uslm:sidenote[contains(@role, 'publicComment')][normalize-space(.)!='']">
                <sup><xsl:number format="1"
                    value="
                    count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                    [contains(@role, 'Comment')]
                    [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                    [if (following::uslm:page) 
                    then (following::uslm:page[1] = current()/following::uslm:page[1])
                    else (true())])+1"
                /></sup></xsl:if>
        </sidenote><xsl:if test="@note and normalize-space(@note)!=''">
            <sidenote>
                <xsl:attribute name="topic" select="'olrcStamp'"/>
                <xsl:if test="@note='CO'">
                    <xsl:attribute name="class">CO</xsl:attribute>
                </xsl:if><xsl:value-of select="@note"/>
            </sidenote></xsl:if>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Handle the case where unenumerated provision classifications and comments are on
                the same level as standard provision classifications</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="
            uslm:sidenote[@topic = 'olrcClassification'][contains(@role, 'arget') or
            contains(@class, 'out')][following-sibling::uslm:num[uslm:marker][uslm:sidenote]]"
        mode="addFootnotes">
        <xsl:variable name="current" select="." as="element()"/>
        <xsl:value-of select="'sidenote with following sibling marker'" use-when="false()"/>
        <sidenote>
            <xsl:apply-templates select="@*[not(name() = 'role')]" mode="#current"/>
            <xsl:choose>
                <xsl:when test="@role">
                    <xsl:attribute name="role">
                        <xsl:value-of select="@role"/>
                        <xsl:value-of
                            select="
                                if (following-sibling::uslm:sidenote[contains(@role, 'publicComment')])
                                then
                                    (', publicComment')
                                else
                                    ()"
                        />
                    </xsl:attribute>
                </xsl:when>
                <xsl:when
                    test="not(@role) and following-sibling::uslm:sidenote[contains(@role, 'publicComment')]">
                    <xsl:attribute name="role">
                        <xsl:value-of select="'publicComment'"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="contains(@class, 'out') or contains(@role, 'target')">
                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:if><xsl:if test="contains(@role, 'longTarget')"><sup><xsl:number format="a"
                    value="
                        count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                        [contains(@role, 'longTarget')]
                        [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                        [if (following::uslm:page) 
                        then (following::uslm:page[1] = current()/following::uslm:page[1])
                        else (true())]) + 1"
                /></sup></xsl:if><xsl:if test="following-sibling::uslm:sidenote[contains(@role, 'publicComment')]"><sup><xsl:number format="1"
                    value="
                        count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                        [contains(@role, 'Comment')]
                        [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                        [if (following::uslm:page) 
                        then (following::uslm:page[1] = current()/following::uslm:page[1])
                        else (true())]) + 1"
                /></sup></xsl:if>
        </sidenote>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Handle the sidenotes in unenumerated provisions</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:num/uslm:sidenote[preceding-sibling::uslm:marker][following-sibling::uslm:marker]
        [not(preceding-sibling::uslm:sidenote[@topic = 'olrcClassification'])]"
        mode="addFootnotes" priority="1">
        <xsl:value-of select="'num with sidenote 674 between markers'" use-when="false()"/>
        <sidenote>
            <xsl:apply-templates select="@*[not(name() = 'role')]" mode="#current"/>
            <xsl:choose>
                <xsl:when test="@role">
                    <xsl:attribute name="role">
                        <xsl:value-of select="@role"/>
                        <xsl:value-of
                            select="
                            if (following-sibling::uslm:sidenote[contains(@role, 'publicComment')])
                            then
                            (', publicComment')
                            else
                            ()"
                        />
                    </xsl:attribute>
                </xsl:when>
                <xsl:when
                    test="not(@role) and following-sibling::uslm:sidenote[contains(@role, 'publicComment')]">
                    <xsl:attribute name="role">
                        <xsl:value-of select="'publicComment'"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="contains(@class, 'out') or contains(@role, 'target')">
                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:if>
            <xsl:if test="contains(@role, 'longTarget')"><sup><xsl:number format="a"
                value="
                count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                [contains(@role, 'longTarget')]
                [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                [if (following::uslm:page) 
                then (following::uslm:page[1] = current()/following::uslm:page[1])
                else (true())]) + 1"
            /></sup></xsl:if>
            <xsl:if test="following-sibling::uslm:sidenote[contains(@role, 'publicComment')]"><sup><xsl:number format="1"
                value="
                count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                [contains(@role, 'Comment')]
                [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                [if (following::uslm:page) 
                then (following::uslm:page[1] = current()/following::uslm:page[1])
                else (true())]) + 1"
            /></sup></xsl:if>
        </sidenote>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Delete the comment sidenotes in the original location.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="uslm:sidenote[@topic = 'olrcClassification'][contains(@role, 'Comment')]
            [preceding-sibling::uslm:sidenote[@topic = 'olrcClassification']]"
        mode="addFootnotes"/>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Footnotes are added before each page element for any public comments on this page,
                as well as the long target listings. </xd:p>
        </xd:desc>
        <xd:param name="meta">metadata input for the plaw page numbers</xd:param>
    </xd:doc>
    <xsl:template
        match="uslm:page[ancestor::uslm:main]"
        mode="addFootnotes">
        <xsl:param name="meta" as="element()*" select="$meta"/>
        <xsl:sequence select="'page one of at least two'" use-when="false()"/>
        <xsl:for-each
            select="preceding::uslm:sidenote[@topic = 'olrcClassification']
                [contains(@role, 'Comment') or contains(@role, 'longTarget')]
                [following::uslm:page[1] = current()]">
            <footnote topic="olrcClassification" role="{./@role}">
                <xsl:choose>
                    <xsl:when test="contains(./@role, 'Comment') and normalize-space(.)!=''">
                        <sup><xsl:number format="1"
                            value="
                            count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                            [contains(@role, 'Comment')]
                            [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                            [if (following::uslm:page) 
                            then (following::uslm:page[1] = current()/following::uslm:page[1])
                            else (true())]) + 1"
                        /></sup>
                    </xsl:when>
                    <xsl:when test="contains(./@role, 'longTarget') and normalize-space(.)!=''">
                        <sup><xsl:number format="a"
                            value="
                            count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                            [contains(@role, 'longTarget')]
                            [preceding::uslm:page[1] = current()/preceding::uslm:page[1]]
                            [if (following::uslm:page) 
                            then (following::uslm:page[1] = current()/following::uslm:page[1])
                            else (true())]) + 1"
                        /></sup>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="createFootnoteContent"/>
            </footnote>
        </xsl:for-each>
        <xsl:if test="$meta and not(following-sibling::uslm:meta)">
            <!-- This test checks whether the ancestor is a standard block
            element. If the ancestor is inline, Chrome has a bug and won't 
            break the page when rendering unless there is a br element there. -->
            <xsl:if test="((ancestor::uslm:content[not(descendant::uslm:quotedContent)]
                or (ancestor::uslm:content and not(ancestor::uslm:quotedContent))
                or ancestor::uslm:chapeau or ancestor::uslm:continuation 
                or ancestor::uslm:text)) and not(ancestor::uslm:toc)">
                <br/><xsl:text>&#xa;</xsl:text>
            </xsl:if>
            <xsl:call-template name="createPageInfo">
                <xsl:with-param name="pageInfo" select="$meta"/>
                <xsl:with-param name="pageNumber" select="number(replace(@id, 'page', '')) - 1"/>
            </xsl:call-template>
        </xsl:if>
        <page>
            <xsl:apply-templates mode="#current" select="@* | node()"/>
        </page>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Move the public comment and long target sidenotes to footnotes when the main
                content has no page breaks.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="
        uslm:main[descendant::uslm:sidenote[@topic = 'olrcClassification']
        [contains(@role, 'Comment') or contains(@role, 'longTarget')]
        [not(following::uslm:page)]]"
        mode="addFootnotes">
        <main>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
            <xsl:value-of use-when="false()" select="'page one of one'"/>
            <xsl:for-each
                select="
                    descendant::uslm:sidenote[@topic = 'olrcClassification']
                    [contains(@role, 'Comment') or contains(@role, 'longTarget')]
                    [not(following::uslm:page)]">
                <footnote topic="olrcClassification" role="{./@role}">
                    <xsl:choose>
                        <xsl:when test="contains(./@role, 'Comment') and normalize-space(.)!=''">
                            <sup><xsl:number format="1"
                                value="
                                    count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                                    [not(following::uslm:page)]
                                    [contains(@role, 'Comment')]) + 1"
                            /></sup>
                        </xsl:when>
                        <xsl:when test="contains(./@role, 'longTarget') and normalize-space(.)!=''">
                            <sup><xsl:number format="a"
                                value="
                                    count(preceding::uslm:sidenote[@topic = 'olrcClassification']
                                    [not(following::uslm:page)]
                                    [contains(@role, 'longTarget')]) + 1"
                            /></sup>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="createFootnoteContent"/>
                </footnote>
            </xsl:for-each>
        </main>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Fix up \n that comes in from the unenumerated provision handling of the sidenotes.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:sidenote[@topic = 'olrcClassification'][contains(@role,'Comment')][normalize-space(.)!='']/text()"
        mode="createFootnoteContent">
        <xsl:analyze-string select="." regex="\\n">
            <xsl:matching-substring>
                <br/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Add the meta information to the page element on the first page, which is outside
                the main element.</xd:p>
        </xd:desc>
        <xd:param name="meta">metadata input for the plaw page numbers</xd:param>
    </xd:doc>
    <xsl:template match="uslm:page[not(ancestor::uslm:main)]" mode="addFootnotes">
        <xsl:param name="meta" as="element()*" select="$meta"/>
        <xsl:sequence select="'first page (not in main)'" use-when="false()"/>
        <xsl:sequence use-when="false()" select="if (empty($meta)) 
            then ('$meta is empty')
            else ('$meta is not empty')"/>
        <xsl:if test="$meta">
            <xsl:call-template name="createPageInfo">
                <xsl:with-param name="pageInfo" select="$meta"/>
                <xsl:with-param name="pageNumber" select="number(replace(@id, 'page', '')) - 1"/>
            </xsl:call-template>
        </xsl:if>
        <page>
            <xsl:apply-templates mode="#current" select="@* | node()"/>
        </page>
    </xsl:template>


    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Add version and processed date information to the meta content. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="uslm:docStage">
        <xsl:copy-of select="." copy-namespaces="no"/>
        <xsl:call-template name="createProcessorInfo"/>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Create version and processed date information to be added to the meta content. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="createProcessorInfo">
        <processedBy>
            <xsl:value-of select="'Annotation service last modified: 2023-06-26'"/>
        </processedBy>
        <processedDate>
            <xsl:value-of select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
        </processedDate>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Create the footnote content from the public comment sidenote.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="uslm:sidenote[@topic = 'olrcClassification'][contains(@role, 'Comment') 
        or contains(@role, 'longTarget')]"
        mode="createFootnoteContent">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Create the footnote content from the target sidenote that contains a CO stamp note.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template
        match="uslm:sidenote[@topic = 'olrcClassification'][@role='target'][@note='CO']"
        mode="createFootnoteContent">
        <xsl:apply-templates select="text()" mode="#current"/>
    </xsl:template>

    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>95% isn't wide enough for people to see properly, so increase to 110%</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="xhtml:table/@width">
        <xsl:if test=". = '95%'">
            <xsl:attribute name="width">110%</xsl:attribute>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
