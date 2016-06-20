<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 19, 2015</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="source.id" select="substring-before(//mei:mdiv/@xml:id,'_mov')" as="xs:string"/>
    <xsl:variable name="mov.n" select="substring-after(//mei:mdiv/@xml:id,'_mov')" as="xs:string"/>
    <xsl:variable name="doc.uri" select="substring-before(string(document-uri()),'data/')" as="xs:string"/>
    <xsl:variable name="core" select="doc(concat($doc.uri,'data/core/core_mov',$mov.n,'.xml'))" as="node()?"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="not($core)">
                <xsl:message select="'Could not open core file. Please check path!'"/>
                <error>Core file could not be found</error>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="filled.up">
                    <xsl:apply-templates select="/mei:mei" mode="query.core"/>
                </xsl:variable>
                <xsl:variable name="abbr" as="node()">
                    <xsl:apply-templates select="$filled.up" mode="get.abbr"/>
                </xsl:variable>
                <xsl:variable name="expan" as="node()">
                    <xsl:apply-templates select="$filled.up" mode="get.expan"/>
                </xsl:variable>
                <xsl:result-document href="{concat($doc.uri,'data/source_abbr/',$source.id,'/',$source.id,'_mov',$mov.n,'.xml')}">
                    <xsl:copy-of select="$abbr"/>
                </xsl:result-document>
                <xsl:result-document href="{concat($doc.uri,'data/source_expan/',$source.id,'/',$source.id,'_mov',$mov.n,'.xml')}">
                    <xsl:copy-of select="$expan"/>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:*[@sameas]" mode="query.core">
        <xsl:variable name="core.id" select="substring-after(@sameas,'#')" as="xs:string"/>
        <xsl:variable name="core.elem" select="$core/id($core.id)" as="node()?"/>
        <xsl:if test="not($core.elem)">
            <xsl:message select="concat('WARNING: reference to ',$core.id,' in core is broken. Pointing element in source: ',parent::mei:*/@xml:id)"/>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* except @sameas" mode="#current"/>
            <xsl:apply-templates select="$core.elem/(@* except @xml:id)" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:choice" mode="get.abbr">
        <xsl:choose>
            <xsl:when test="child::mei:corr">
                <xsl:apply-templates select="child::mei:corr[1]/mei:*" mode="#current"/>
            </xsl:when>
            <xsl:when test="child::mei:abbr">
                <xsl:apply-templates select="child::mei:abbr/mei:*" mode="#current"/>
            </xsl:when>
            <xsl:when test="child::mei:orig">
                <xsl:apply-templates select="child::mei:orig/mei:*" mode="#current"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:choice" mode="get.expan">
        <xsl:choose>
            <xsl:when test="child::mei:corr">
                <xsl:apply-templates select="child::mei:corr[1]/mei:*" mode="#current"/>
            </xsl:when>
            <xsl:when test="child::mei:expan">
                <xsl:apply-templates select="child::mei:expan/mei:*" mode="#current"/>
            </xsl:when>
            <xsl:when test="child::mei:reg">
                <xsl:apply-templates select="child::mei:reg[1]/mei:*" mode="#current"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:meiHead" mode="query.core"/>
    <xsl:template match="mei:facsimile" mode="query.core"/>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>