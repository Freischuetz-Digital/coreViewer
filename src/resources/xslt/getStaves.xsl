<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="local" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 24, 2015</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="solo" as="xs:string?"/>
    <xsl:param name="muted" as="xs:string?"/>
    <xsl:variable name="muted.n" select="if($muted) then(tokenize($muted,' ')) else()" as="xs:string*"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="exists($solo) and not($solo = //mei:staffDef/@n)">
                <xsl:copy-of select="/"/>
            </xsl:when>
            <xsl:when test="exists($solo)">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="count($muted.n) gt 0">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="/"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:staff">
        <xsl:choose>
            <xsl:when test="$solo and not(@n = $solo)"/>
            <xsl:when test="@n = $muted.n"/>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:staffDef">
        <xsl:choose>
            <xsl:when test="$solo and not(@n = $solo)"/>
            <xsl:when test="@n = $muted.n"/>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:*[@staff]">
        <xsl:choose>
            <xsl:when test="$solo and not(@staff = $solo)"/>
            <xsl:when test="@staff = $muted.n"/>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:staffGrp">
        <xsl:choose>
            <xsl:when test="$solo and not($solo = .//mei:staffDef/@n)"/>
            <xsl:when test="every $staffDef in .//mei:staffDef satisfies $staffDef/@n = $muted.n"/>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>