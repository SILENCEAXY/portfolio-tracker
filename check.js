const fs = require('fs');
const c = fs.readFileSync('C:/Users/SILENCE/.qclaw/workspace/portfolio-deploy/index.html', 'utf8');
const scriptStart = c.lastIndexOf('<script>') + 8;
const scriptEnd = c.lastIndexOf('</script>');
const js = c.substring(scriptStart, scriptEnd);
try {
  new Function(js);
  console.log('✅ SYNTAX OK');
} catch (e) {
  console.log('❌ ERROR:', e.message);
}
