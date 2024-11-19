
FROM node:18-bullseye
# Installing libvips-dev for sharp Compatability
ENV NODE_ENV=${NODE_ENV}
# ENV PATH /opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .

RUN yarn config set network-timeout 550000 -g && yarn install
RUN yarn build
EXPOSE 1337
CMD ["yarn", "start"]
