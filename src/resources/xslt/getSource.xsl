<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="local" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 21, 2014</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="perspective" as="xs:string"/>
    <!-- allowed values: abbr | expan -->
    <xsl:param name="header" as="xs:string"/>
    <!-- allowed values: strip | preserve -->
    <xsl:template match="/">
        
        <!-- provide useful error messages in case of incorrect parameters -->
        <xsl:choose>
            <xsl:when test="not($perspective = ('abbr','expan'))">
                <error>A value of "<xsl:value-of select="$perspective"/>" is not allowed for param $perspective of getSource.xsl. Processing terminated.</error>
            </xsl:when>
            <xsl:when test="not($header = ('strip','preserve'))">
                <error>A value of "<xsl:value-of select="$header"/>" is not allowed for param $header of getSource.xsl. Processing terminated.</error>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- decide if meiHead needs to be stripped -->
    <xsl:template match="mei:meiHead" mode="#all">
        <xsl:choose>
            <xsl:when test="$header = 'preserve'">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- strip facsimile in all cases -->
    <xsl:template match="mei:facsimile" mode="#all"/>
    
    <!-- decide how to deal with choices -->
    <xsl:template match="mei:choice" mode="#all">
        <xsl:choose>
            <!-- always use corrections -->
            <xsl:when test="child::mei:corr">
                <xsl:apply-templates select="child::mei:corr[1]/mei:*" mode="#current"/>
            </xsl:when>
            <!-- show orig and abbr -->
            <xsl:when test="$perspective = 'abbr'">
                <xsl:apply-templates select="child::mei:orig/mei:* | child::mei:abbr/mei:*" mode="#current"/>
            </xsl:when>
            <!-- show reg and expan -->
            <xsl:when test="$perspective = 'expan'">
                <xsl:apply-templates select="child::mei:reg/mei:* | child::mei:expan/mei:*" mode="#current"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>