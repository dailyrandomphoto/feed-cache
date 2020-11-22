const read = require("node-read-yaml");
const { writeFile } = require("fs-extra");

function handleItem(item, paths, result) {
  if (item["_url"]) {
    const title = item["_title"] ? { title: item["_title"] } : null;
    const tags = item["_tags"] ? { tags: item["_tags"] } : null;
    result.push(
      Object.assign(
        {
          path: paths.join("/") + "/feed.xml",
          url: item["_url"]
        },
        title,
        tags
      )
    );
  }

  for (let key in item) {
    if (!key.startsWith("_")) {
      paths.push(key);
      handleItem(item[key], paths, result);
      paths.pop();
    }
  }
}

read("list.yml")
  .then(doc => {
    console.debug(doc);
    const result = [];
    handleItem(doc, [], result);
    result.sort((a, b) => {
      return a.path > b.path;
    });
    console.debug(result);
    return result;
  })
  .then(list =>
    writeFile(
      "fetch-list.txt",
      list.map(item => `${item.path}\t${item.url}`).join("\n") + "\n"
    )
  )
  .catch(err => console.error(err));
