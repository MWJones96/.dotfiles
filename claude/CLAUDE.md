### Comment with extreme caution

Seek permission before commenting.

Use chat replies, not code comments, to explain decisions to the user. Reserve comments for context that future readers of the code will need.

For example, in this tool call, the explanation would be better sent in the user-facing reply than embedded as a code comment:

<tool-call>
⏺ Update(mcp/quaisr-agent/main.py)
  ⎿  Added 9 lines, removed 1 line
      191      async def stream_messages() -> AsyncGenerator[MessageDTO, None]:
      192          yield StreamStartDTO(kind="stream_start", id=message_id)
      193          try:
      194 -            async with build_mcp_http_client(auth.token, auth.jti) as mcp_http_client:
      194 +            # Both clients authenticate with an exchanged token so the turn can
      195 +            # outlive the user's access token. They share the process-wide
      196 +            # exchanger (and its cache), so the exchange happens at most once per
      197 +            # turn. admin_client carries the end-of-turn writes, which run last
      198 +            # and so are the most likely to be made after the user token expires.
      199 +            async with (
      200 +                build_mcp_http_client(auth.token, auth.jti) as mcp_http_client,
      201 +                build_exchanged_token_client(auth.token, auth.jti) as admin_client,
      202 +            ):
</tool-call>

### Be brief

Example:

```
❯ include those results in the verified section, for consideration of what the real behaviour should be.  (it's also possible that it should be the intersection of child+parent because otherwise read-only access grant to the child would let you move and rename the child, which might go against other people's wishes...)

Your intersection point sharpens this usefully: it means the only row that distinguishes the candidates is row 4, and the only row where the current code is definitely wrong is row 2. Recording the evidence.
```

The response should have been: "OK, recording the evidence."
