<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/">
  <html>
    <head>
      <link href="computers.css" rel="stylesheet" type="text/css" />
      <title>Lab Status - <xsl:value-of select="lab_status/long_time" /></title>
	</head>
	<body>
      <form method="post" action="computers.pl">
        <xsl:for-each select="lab_status/lab">
          <table>
            <tr>
              <td id="title" colspan="10">
                <xsl:value-of select="description" />
              </td>
            </tr>
            <tr>
              <th class="computer">Computer</th>
              <th class="status">Status</th>
              <th class="ip">IP</th>
              <th class="mac">MAC</th>
              <th class="lastUser">Last User</th>
              <th class="currentUser">Current User</th>
              <th class="refresh">Refresh</th>
              <th class="wol">WOL</th>
              <th class="shutdown">Shutdown</th>
              <th class="restart">Restart</th>
            </tr>
            <xsl:for-each select="computer">
              <xsl:sort select="hostname" />
              <xsl:variable name="rowID">
                <xsl:choose>
                  <xsl:when test="status[1] = 'active'">
                    <xsl:choose>
                      <xsl:when test="position() mod 2 = 0">evenRow</xsl:when>
                      <xsl:otherwise>oddRow</xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:when test="status[1] = 'unreachable'">unreachable</xsl:when>
                  <xsl:when test="status[1] = 'login error'">loginError</xsl:when>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="hostname" select="hostname" />
              <xsl:variable name="status" select="status[1]" />
              <xsl:variable name="ip" select="ip[1]" />
              <xsl:variable name="mac" select="mac[1]" />
              <xsl:variable name="last_user" select="last_user[1]" />
              <xsl:variable name="current_user" select="current_user[1]" />
              <tr id="{$rowID}">
                <td><xsl:value-of select="hostname" /></td>
                <td><xsl:value-of select="status[1]" /></td>
                <td><xsl:value-of select="ip[1]" /></td>
                <td><xsl:value-of select="mac[1]" /></td>
                <td><xsl:value-of select="last_user[1]" /></td>
                <td><xsl:value-of select="current_user[1]" /></td>
                <td align="center"><input type="checkbox" name="refresh:{$hostname}" /></td>
                <td align="center"><input type="checkbox" name="wol:{$hostname}" /></td>
                <td align="center"><input type="checkbox" name="shutdown:{$hostname}" /></td>
                <td align="center"><input type="checkbox" name="restart:{$hostname}" /></td>
              </tr>
            </xsl:for-each>
            <tr>
              <td colspan="6"></td>
              <td><input type="submit" name="refresh" value="Refresh" /></td>
              <td><input type="submit" name="wol" value="Wake" /></td>
              <td><input type="submit" name="shutdown" value="Shutdown" /></td>
              <td><input type="submit" name="restart" value="Restart" /></td>
            </tr>
          </table>
          <div style="line-height: 1.5;">&#160;</div>
        </xsl:for-each>
      </form>
    </body>
  </html>
</xsl:template>


</xsl:stylesheet>